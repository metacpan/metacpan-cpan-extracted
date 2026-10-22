#!/usr/bin/env perl
# k70: the exec credential plugin was started with backticks ("$cmd @args"),
# so a shell parsed the args: a space split one argument in two, quotes were
# eaten, "$", ";", "*" and "&" were interpreted, and a failing plugin was
# reported without its exit status. The plugin must start without a shell,
# with each configured arg arriving as exactly one argv element, its stderr
# must stay visible (a login helper's prompt or error is the only hint why it
# failed) and a failure must name the exit status.
#
# Everything is a temporary script; no test here reaches a cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use Path::Tiny qw(path);
use JSON::MaybeXS ();
use YAML::XS ();

use_ok('Kubernetes::REST::Kubeconfig');

my $tmpdir = tempdir(CLEANUP => 1);
local $ENV{HOME} = $tmpdir;
delete local $ENV{KUBECONFIG};

my $json = JSON::MaybeXS->new(canonical => 1);

sub plugin {
    my ($name, $body) = @_;
    my $file = "$tmpdir/$name";
    path($file)->spew("#!$^X\n$body");
    chmod 0755, $file or die "Cannot chmod $file: $!";
    return $file;
}

# Prints its argv, JSON encoded, as the token.
my $echo = plugin('echo-args', <<'PERL');
use JSON::PP ();
my $argv = JSON::PP->new->canonical->encode([@ARGV]);
print JSON::PP->new->encode({ status => { token => $argv } }), "\n";
PERL

# Complains on stderr, then hands out a token.
my $chatty = plugin('chatty', <<'PERL');
print STDERR "plugin-says-login-expired\n";
print qq({"status":{"token":"after-stderr"}}\n);
PERL

my $failing = plugin('failing', <<'PERL');
print STDERR "plugin-failure-detail\n";
exit 3;
PERL

sub api_for {
    my (%exec) = @_;
    my $config = "$tmpdir/kubeconfig";
    YAML::XS::DumpFile($config, {
        apiVersion => 'v1',
        kind => 'Config',
        'current-context' => 'ctx',
        clusters => [{ name => 'c', cluster => {
            server => 'https://cluster.k8s.test:6443',
            'insecure-skip-tls-verify' => 1,
        } }],
        contexts => [{ name => 'ctx', context => { cluster => 'c', user => 'u' } }],
        users => [{ name => 'u', user => { exec => {
            apiVersion => 'client.authentication.k8s.io/v1',
            %exec,
        } } }],
    });
    return Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config)->api;
}

# The token, or undef plus a diagnostic: a croak inside the code under test
# must fail one assertion, not end the file.
sub token_of {
    my (%exec) = @_;
    my $token = eval { api_for(%exec)->credentials->token };
    diag "api_for died: $@" if $@;
    return $token;
}

# Runs $code with fd 2 pointed at a file (a real dup of the descriptor, so a
# child process inherits it) and returns what was written there.
sub capture_stderr {
    my ($code) = @_;
    my $file = "$tmpdir/stderr-capture";
    unlink $file;
    open my $saved, '>&', \*STDERR or die "Cannot dup STDERR: $!";
    open STDERR, '>', $file or die "Cannot redirect STDERR: $!";
    my @result = eval { $code->() };
    my $err = $@;
    close STDERR;
    open STDERR, '>&', $saved or die "Cannot restore STDERR: $!";
    close $saved;
    return (scalar path($file)->slurp_raw, $err, @result);
}

subtest 'a plugin given a shell-style script argument gets it intact' => sub {
    is token_of(
        command => '/bin/sh',
        args => ['-c', q{echo '{"status":{"token":"abc"}}'}],
    ), 'abc', 'the -c script arrived as one argument';
};

subtest 'every arg arrives as exactly one unchanged argv element' => sub {
    my @args = (
        'plain',
        'with space',
        q{single'quote},
        'double"quote',
        '$HOME',
        'semi;colon',
        '*',
        'amp&ersand',
        q{two  spaces 'and' "both"},
        '',
    );
    my $token = token_of(command => $echo, args => \@args);
    is_deeply eval { $json->decode($token // 'null') }, \@args,
        'argv is exactly the configured list';
};

subtest 'a command path containing a space is not split' => sub {
    mkdir "$tmpdir/dir with space" or die $!;
    my $spaced = plugin('dir with space/plugin', <<'PERL');
print qq({"status":{"token":"from-spaced-path"}}\n);
PERL
    is token_of(command => $spaced), 'from-spaced-path',
        'started by its path, not by a shell word';
};

subtest 'the configured env reaches the plugin' => sub {
    my $env = plugin('env', <<'PERL');
print qq({"status":{"token":"$ENV{K70_TEST}"}}\n);
PERL
    is token_of(command => $env, env => [{ name => 'K70_TEST', value => 'a b;c' }]),
        'a b;c', 'value untouched';
};

subtest 'stderr of the plugin stays visible' => sub {
    my ($seen, $err, $token) = capture_stderr(sub { token_of(command => $chatty) });
    is $err, '', 'the plugin succeeded';
    like $seen, qr/plugin-says-login-expired/, 'its stderr text reached our stderr';
    is $token, 'after-stderr', 'and the token still came through';
};

subtest 'a failing plugin: exit status in the message, stderr visible' => sub {
    my ($seen, $err) = capture_stderr(sub { api_for(command => $failing) });
    $err = "$err";
    like $err, qr/exited with status 3/, 'the message names the exit status';
    like $err, qr/\Q$failing\E/, 'and the command';
    like $seen, qr/plugin-failure-detail/, 'the plugin stderr was not swallowed';
};

subtest 'a command that does not exist croaks, with or without args' => sub {
    my $missing = "$tmpdir/no-such-plugin";
    my $name = quotemeta $missing;
    throws_ok { api_for(command => $missing) } qr/$name/,
        'no args: the error names the command';
    throws_ok { api_for(command => $missing, args => ['get-token', '--x y']) } qr/$name/,
        'with args: the error names the command';
    unlike $@, qr/exited with status/, 'it never ran, so no exit status is claimed';
};

done_testing;
