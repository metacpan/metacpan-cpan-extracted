#!/usr/bin/env perl
# A user authenticating through "tokenFile: /path/to/token" - a projected
# service account token, a file some login helper refreshes - was not read at
# all: the user matched neither "token" nor "exec", fell into the client-cert
# branch and got an empty bearer token, so every request came back 401 while
# the same kubeconfig worked with kubectl.
#
# The order this file pins is kubectl's, taken from client-go:
# getUserIdentificationPartialConfig reads the file only when there is no
# inline token ("else if len(configAuthInfo.TokenFile) > 0"), and the exec
# plugin round tripper returns early "if req.Header.Get("Authorization") !=
# ''", so a token of either kind means the plugin never runs. An unreadable
# file is fatal there too, and the file token source trims the content and
# rejects what is left when it is empty.
#
# HOME and KUBECONFIG are localised, everything lives in one temporary
# directory, and no test here reaches a cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use Cwd qw(getcwd);
use Path::Tiny qw(path);
use YAML::XS ();

use_ok('Kubernetes::REST::Kubeconfig');

my $tmpdir = tempdir(CLEANUP => 1);
local $ENV{HOME} = $tmpdir;
delete local $ENV{KUBECONFIG};

make_path("$tmpdir/$_") for qw(conf elsewhere);

# An exec plugin that leaves a trace, so "the plugin did not run" is something
# this file can actually assert rather than infer from the token it did not
# produce. No arguments: Kubeconfig runs the command through the shell and
# interpolates args unquoted.
my $exec_marker = "$tmpdir/exec-ran";
my $exec_plugin = "$tmpdir/credential-plugin";
path($exec_plugin)->spew(<<"PERL");
#!$^X
open my \$fh, '>', '$exec_marker' or die "cannot mark: \$!";
close \$fh;
print "status:\\n  token: token-from-exec\\n";
PERL
chmod 0755, $exec_plugin or die "Cannot chmod $exec_plugin: $!";

sub exec_ran {
    my $ran = -e $exec_marker;
    unlink $exec_marker;
    return $ran;
}

sub write_token {
    my ($path, $content) = @_;
    path($path)->spew_raw($content);
    return $path;
}

# The token file every ordinary case reads, newline-terminated the way a real
# one is.
write_token("$tmpdir/conf/token", "token-from-file\n");

# One kubeconfig, one user per case. Every cluster is the same, only the user
# entries differ, so a test says which credential branch was taken and nothing
# else.
my $config = "$tmpdir/conf/kubeconfig";
YAML::XS::DumpFile($config, {
    apiVersion => 'v1',
    kind => 'Config',
    'current-context' => 'file-ctx',
    clusters => [{
        name => 'test-cluster',
        cluster => {
            server => 'https://cluster.k8s.test:6443',
            'insecure-skip-tls-verify' => 1,
        },
    }],
    contexts => [
        map { { name => "$_-ctx", context => { cluster => 'test-cluster', user => "$_-user" } } }
            qw(file inline both exec file-and-exec missing missing-and-exec empty blank crlf spaces none)
    ],
    users => [
        # tokenFile alone, named relatively: the point of #12 applied to this field.
        { name => 'file-user', user => { tokenFile => 'token' } },
        # An inline token, unchanged behaviour.
        { name => 'inline-user', user => { token => 'token-from-inline' } },
        # Both: kubectl reads the file only when there is no inline token.
        { name => 'both-user', user => { token => 'token-from-inline', tokenFile => 'token' } },
        # exec alone, unchanged behaviour.
        { name => 'exec-user', user => { exec => {
            apiVersion => 'client.authentication.k8s.io/v1',
            command => $exec_plugin,
        } } },
        # tokenFile and exec: the file wins and the plugin must stay unrun.
        { name => 'file-and-exec-user', user => { tokenFile => 'token', exec => {
            apiVersion => 'client.authentication.k8s.io/v1',
            command => $exec_plugin,
        } } },
        # A tokenFile that is not there.
        { name => 'missing-user', user => { tokenFile => 'no-such-token' } },
        # ... and one with an exec block behind it, which must not rescue it.
        { name => 'missing-and-exec-user', user => { tokenFile => 'no-such-token', exec => {
            apiVersion => 'client.authentication.k8s.io/v1',
            command => $exec_plugin,
        } } },
        # Empty file, and one holding only whitespace.
        { name => 'empty-user', user => { tokenFile => 'empty-token' } },
        { name => 'blank-user', user => { tokenFile => 'blank-token' } },
        # Files with the whitespace real ones come with.
        { name => 'crlf-user', user => { tokenFile => 'crlf-token' } },
        { name => 'spaces-user', user => { tokenFile => 'spaces-token' } },
        # Neither token nor tokenFile nor exec: client certificates only.
        { name => 'none-user', user => {} },
    ],
});

write_token("$tmpdir/conf/empty-token", '');
write_token("$tmpdir/conf/blank-token", "\n  \n");
write_token("$tmpdir/conf/crlf-token", "token-from-crlf\r\n");
write_token("$tmpdir/conf/spaces-token", "  token-from-spaces \n\n");

# Never run from the directory the kubeconfig or its token files live in.
my $start = getcwd;
chdir "$tmpdir/elsewhere" or die "Cannot chdir to $tmpdir/elsewhere: $!";
END { chdir $start if $start }

sub kc { Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config) }

subtest 'a tokenFile is read and becomes the bearer token' => sub {
    my $api = kc()->api('file-ctx');
    is $api->credentials->token, 'token-from-file', 'the file content is the token';

    my $req = $api->prepare_request('GET', '/api/v1/namespaces');
    is $req->headers->{Authorization}, 'Bearer token-from-file',
        'and it is what the request carries';
};

subtest 'the current-context user gets it too' => sub {
    # file-ctx is the current context: the plain "->api" path, which is what
    # anyone reading a kubeconfig actually calls.
    is kc()->api->credentials->token, 'token-from-file',
        'api() without a context name reads the tokenFile as well';
};

subtest 'a relative tokenFile resolves against the kubeconfig directory' => sub {
    is kc()->user('file-user')->{tokenFile}, "$tmpdir/conf/token",
        'the path was made absolute while the file was read';

    my @seen;
    for my $where ("$tmpdir/elsewhere", $tmpdir, "$tmpdir/conf") {
        chdir $where or die "Cannot chdir to $where: $!";
        push @seen, kc()->api('file-ctx')->credentials->token;
    }
    chdir "$tmpdir/elsewhere" or die "Cannot chdir back: $!";
    is_deeply \@seen, [('token-from-file') x 3],
        'read from three working directories, same token every time';
};

subtest 'an inline token still wins over a tokenFile' => sub {
    # client-go: "if len(configAuthInfo.Token) > 0 { ... } else if
    # len(configAuthInfo.TokenFile) > 0". Adding tokenFile support must not
    # change what an existing kubeconfig carrying both already means.
    is kc()->api('both-ctx')->credentials->token, 'token-from-inline',
        'the inline token is the one used';
    isnt kc()->api('both-ctx')->credentials->token, 'token-from-file',
        'the file is not consulted';
};

subtest 'a tokenFile wins over an exec plugin, which does not run' => sub {
    ok !exec_ran(), 'no stale marker from an earlier case';
    my $api = kc()->api('file-and-exec-ctx');
    is $api->credentials->token, 'token-from-file', 'the token comes from the file';
    ok !exec_ran(), 'the exec plugin was never started';
};

subtest 'an exec plugin is still used when it is the only credential' => sub {
    my $api = kc()->api('exec-ctx');
    is $api->credentials->token, 'token-from-exec', 'exec credentials keep working';
    ok exec_ran(), 'and the plugin really did run';
};

subtest 'an inline token still wins over an exec plugin' => sub {
    is kc()->api('inline-ctx')->credentials->token, 'token-from-inline', 'inline token';
    ok !exec_ran(), 'no plugin involved';
};

subtest 'a user with no credentials at all is unchanged' => sub {
    my $api = kc()->api('none-ctx');
    is $api->credentials->token, '', 'empty token, for client-certificate-only setups';
    my $req = $api->prepare_request('GET', '/api/v1/namespaces');
    ok !exists $req->headers->{Authorization}, 'and no Authorization header at all';
};

subtest 'a missing tokenFile is fatal, not a silent fallback' => sub {
    throws_ok { kc()->api('missing-ctx') } qr/tokenFile of user 'missing-user'/,
        'the error names the user whose file could not be read';
    throws_ok { kc()->api('missing-ctx') } qr/\Q$tmpdir\E.*no-such-token/,
        'and the path it looked for, resolved';

    # The dangerous shape: falling through here would build a working-looking
    # client that collects 401s with nothing pointing at the token file.
    throws_ok { kc()->api('missing-and-exec-ctx') } qr/tokenFile of user/,
        'an exec block behind a broken tokenFile does not paper over it';
    ok !exec_ran(), 'and the plugin was not run instead';
};

subtest 'a tokenFile holding no token is fatal too' => sub {
    throws_ok { kc()->api('empty-ctx') } qr/holds no token/,
        'an empty file is not an empty token';
    throws_ok { kc()->api('blank-ctx') } qr/holds no token/,
        'neither is a file with nothing but whitespace';
    throws_ok { kc()->api('blank-ctx') } qr/tokenFile of user 'blank-user'/,
        'the error names the user';
};

subtest 'surrounding whitespace is stripped' => sub {
    # The usual case: the file ends in a newline. "Bearer token\n" is a broken
    # header, and the kind of broken that only the far end notices.
    my $api = kc()->api('file-ctx');
    is $api->credentials->token, 'token-from-file', 'no trailing newline in the token';
    unlike $api->credentials->token, qr/\s/, 'no whitespace anywhere in it';

    is kc()->api('crlf-ctx')->credentials->token, 'token-from-crlf',
        'a CRLF-terminated file loses both characters';
    is kc()->api('spaces-ctx')->credentials->token, 'token-from-spaces',
        'leading spaces and trailing blank lines go too';

    for my $context (qw(file-ctx crlf-ctx spaces-ctx)) {
        my $header = kc()->api($context)->prepare_request('GET', '/api/v1/namespaces')
            ->headers->{Authorization};
        unlike $header, qr/[\r\n]/, "$context: no line break in the Authorization header";
    }
};

done_testing;
