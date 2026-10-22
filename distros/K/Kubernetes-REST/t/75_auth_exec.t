#!/usr/bin/env perl
# k73: an exec credential plugin's token was frozen into a plain AuthToken, so
# a process built from an EKS/GKE/AKS kubeconfig started getting 401 once the
# token expired (15 minutes to an hour). Kubernetes::REST::AuthExec keeps the
# plugin and runs it again when status.expirationTimestamp is reached or near
# (expiry_margin seconds ahead). Without an expirationTimestamp the token is
# fetched once and never again. A failed re-run keeps the last good token with
# a warning; only the first run, in the constructor, is fatal. A plugin that
# hands out a client certificate instead of a token is refused with a message
# saying so.
#
# Every plugin is a temporary script counting its runs in a temporary file;
# the clock is the real one with generous distances. No test reaches a cluster.
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;
use FindBin;
use lib "$FindBin::Bin/../lib";
use File::Temp qw(tempdir);
use Path::Tiny qw(path);
use YAML::XS ();

use Kubernetes::REST::Kubeconfig;

my $tmpdir = tempdir(CLEANUP => 1);
local $ENV{HOME} = $tmpdir;
delete local $ENV{KUBECONFIG};

my $class = 'Kubernetes::REST::AuthExec';
my $loaded = ok(eval "require $class; 1", "$class loads") or diag $@;

my $seq = 0;

# A plugin that counts its runs in a file and answers "tok-N". $expiry is the
# offset in seconds from now of expirationTimestamp (undef: none). $fail_from
# makes every run from that number on exit 1.
sub counting_plugin {
    my (%opt) = @_;
    my $id = ++$seq;
    my $counter = "$tmpdir/counter-$id";
    path($counter)->spew('0');
    my $expiry = defined $opt{expiry} ? $opt{expiry} : 'undef';
    my $fail_from = $opt{fail_from} // 0;
    my $file = "$tmpdir/plugin-$id";
    path($file)->spew("#!$^X\n" . <<"PERL");
use POSIX ();
my \$n = do { open my \$f, '<', '$counter' or die; local \$/; <\$f> } + 1;
open my \$o, '>', '$counter' or die; print \$o \$n; close \$o;
if ($fail_from && \$n >= $fail_from) { print STDERR "plugin-run-\$n-fails\\n"; exit 1 }
my \$status = { token => "tok-\$n" };
my \$off = $expiry;
\$status->{expirationTimestamp} = POSIX::strftime('%Y-%m-%dT%H:%M:%SZ', gmtime(time + \$off))
    if defined \$off;
require JSON::PP;
print JSON::PP->new->encode({ apiVersion => 'client.authentication.k8s.io/v1', kind => 'ExecCredential', status => \$status }), "\\n";
PERL
    chmod 0755, $file or die "Cannot chmod $file: $!";
    return ($file, sub { 0 + path($counter)->slurp });
}

sub auth_for {
    my ($command, %extra) = @_;
    my $auth = eval { $class->new(command => $command, %extra) };
    diag "construction died: $@" if $@;
    return $auth;
}

sub api_for {
    my ($command) = @_;
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
            command => $command,
        } } }],
    });
    return Kubernetes::REST::Kubeconfig->new(kubeconfig_path => $config)->api;
}

subtest 'no expirationTimestamp: fetched once, never again' => sub {
    my ($cmd, $runs) = counting_plugin();
    my $auth = auth_for($cmd) or return fail('no credential object');
    is $auth->token, 'tok-1', 'token from the first run' for 1 .. 5;
    is $runs->(), 1, 'the plugin ran exactly once';
};

subtest 'expiry far in the future: fetched once' => sub {
    my ($cmd, $runs) = counting_plugin(expiry => 3600);
    my $auth = auth_for($cmd) or return fail('no credential object');
    is $auth->token, 'tok-1', 'token from the first run' for 1 .. 5;
    is $runs->(), 1, 'the plugin ran exactly once';
};

subtest 'expiry in the past: every token() runs the plugin again' => sub {
    my ($cmd, $runs) = counting_plugin(expiry => -3600);
    my $auth = auth_for($cmd) or return fail('no credential object');
    is $runs->(), 1, 'one run when built';
    is $auth->token, 'tok-2', 'first token() returns the fresh token';
    is $auth->token, 'tok-3', 'second token() runs it again';
    is $runs->(), 3, 'three runs in all';
};

subtest 'expiry_margin: a near expiry counts as expired' => sub {
    my ($cmd, $runs) = counting_plugin(expiry => 30);
    my $auth = auth_for($cmd) or return fail('no credential object');
    is $auth->token, 'tok-2', 'default margin (60s): expiry in 30s is near, runs again';
    is $runs->(), 2, 'two runs';

    my ($cmd2, $runs2) = counting_plugin(expiry => 30);
    my $small = auth_for($cmd2, expiry_margin => 5) or return fail('no credential object');
    is $small->token, 'tok-1', 'expiry_margin => 5: expiry in 30s is not near';
    is $runs2->(), 1, 'one run';
    is $small->expiry_margin, 5, 'expiry_margin reads back';
};

subtest 'a failing re-run keeps the last good token and warns' => sub {
    my ($cmd, $runs) = counting_plugin(expiry => -3600, fail_from => 2);
    my $auth = auth_for($cmd) or return fail('no credential object');
    my $token;
    warning_like { $token = $auth->token } qr/\S/, 'the failed re-run is reported as a warning';
    is $token, 'tok-1', 'the last good token is returned';
    is $runs->(), 2, 'the plugin was run again';
};

subtest 'a failing first run is fatal and names the exit status' => sub {
    my ($cmd) = counting_plugin(fail_from => 1);
    throws_ok { $class->new(command => $cmd) } qr/exited with status 1/,
        'construction dies with the exit status';
};

subtest 'a plugin handing out a client certificate is refused' => sub {
    my $cert = "$tmpdir/cert-plugin";
    path($cert)->spew("#!$^X\n" . <<'PERL');
print qq({"status":{"clientCertificateData":"CERT","clientKeyData":"KEY"}}\n);
PERL
    chmod 0755, $cert or die $!;
    my $re = qr/only token plugins are supported.*client certificate/is;
    throws_ok { $class->new(command => $cert) } $re, 'AuthExec says so';
    throws_ok { api_for($cert) } $re, 'and so does Kubeconfig->api';
};

subtest 'Kubeconfig->api builds an AuthExec credential' => sub {
    my ($cmd) = counting_plugin(expiry => 3600);
    my $api = eval { api_for($cmd) } or return fail("api_for died: $@");
    isa_ok $api->credentials, $class, 'credentials';
    is $api->credentials->token, 'tok-1', 'and it hands out the plugin token';
};

done_testing;
