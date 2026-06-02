use strict;
use warnings;
use Test::More;
use POSIX ();
use if -d 'blib', lib => 'blib/lib', 'blib/arch';

# Author test: WebSocket protocol conformance via the Autobahn TestSuite
# fuzzingclient, run against this module's echo server. Needs a container
# runtime (docker or podman; set $EV_WS_OCI to force one) and is Linux-oriented
# (uses --network host so the container can reach the host server).
# Run with: AUTHOR_TESTING=1 prove -lb xt/
#
# This asserts the CORE RFC 6455 conformance the module implements: framing,
# fragmentation, control frames, close handling, and limits. Some groups are
# excluded as out of scope (not conformance failures):
#   6.*, 7.5.*  UTF-8 validity (text + close reason): the module is
#               byte-transparent and does not enable lws's UTF-8 validation.
#   12.*, 13.*  permessage-deflate: compression is optional and not offered by
#               the server vhost (enabling it needs a server-tuned deflate
#               config -- the client-tuned one is non-conformant for a server).
#   2.10        burst of pings: lws coalesces auto-pongs, which Autobahn flags;
#               this is lws control-frame behaviour, not the module's logic.

plan skip_all => "set AUTHOR_TESTING=1 to run the Autobahn suite"
    unless $ENV{AUTHOR_TESTING};

# Container runtime: honour $EV_WS_OCI, else auto-detect docker or podman.
my $oci = $ENV{EV_WS_OCI};
unless ($oci) {
    for my $c (qw(docker podman)) {
        chomp(my $p = `command -v $c 2>/dev/null` || '');
        $oci = $c, last if $p;
    }
}
plan skip_all => "no container runtime (docker/podman) found" unless $oci;

# Create the shared temp dir BEFORE forking so parent and child agree on the
# path (the child publishes its port there; the parent reads it back).
require File::Temp;
require File::Spec;
my $dir = File::Temp->newdir(CLEANUP => 1);

my $forkpid = eval { fork() };
plan skip_all => "fork unavailable: $!" unless defined $forkpid;

if (!$forkpid) {
    # Child: echo server; publish the bound port, then service the loop.
    require EV;
    require EV::Websockets;
    my $ctx  = EV::Websockets::Context->new;
    my $port = $ctx->listen(
        port       => 0,
        max_message_size => 0,
        on_message => sub { my ($c, $d, $bin) = @_; $d //= ''; $bin ? $c->send_binary($d) : $c->send($d) },
    );
    open my $fh, '>', File::Spec->catfile("$dir", 'port') or POSIX::_exit(1);
    print $fh $port; close $fh;
    EV::run();
    POSIX::_exit(0);
}

# Parent: wait for the child to publish its port.
my $portfile = File::Spec->catfile("$dir", 'port');
my $port;
for (1 .. 50) {
    if (-s $portfile) { open my $fh, '<', $portfile; chomp($port = <$fh>); last }
    select undef, undef, undef, 0.1;
}

sub cleanup { kill 'TERM', $forkpid; waitpid $forkpid, 0 }

unless ($port) { cleanup(); plan skip_all => "echo server did not start" }

# fuzzingclient spec.
require JSON::PP;
my $spec = File::Spec->catfile("$dir", 'fuzzingclient.json');
open my $sf, '>', $spec or do { cleanup(); plan skip_all => "cannot write spec" };
print $sf JSON::PP->new->encode({
    outdir        => '/spec/reports',
    servers       => [ { agent => 'EV-Websockets', url => "ws://127.0.0.1:$port" } ],
    cases         => ['*'],
    'exclude-cases' => ['6.*', '7.5.*', '2.10', '12.*', '13.*'],
});
close $sf;

# Fully-qualified image (rootless podman won't resolve short names); :z relabels
# the mounted dir where needed (no-op without SELinux). --network host lets the
# container reach the echo server on the host's 127.0.0.1.
my @cmd = ($oci, 'run', '--rm', '--network', 'host',
           '-v', "$dir:/spec:z", 'docker.io/crossbario/autobahn-testsuite',
           'wstest', '-m', 'fuzzingclient', '-s', '/spec/fuzzingclient.json');
my $rc = system @cmd;
cleanup();

if ($rc != 0) {
    plan skip_all => "could not run autobahn-testsuite ($oci image/network?): rc=$rc";
}

my $report = File::Spec->catfile("$dir", 'reports', 'index.json');
open my $rf, '<', $report or do { plan skip_all => "no autobahn report produced" };
my $idx = JSON::PP->new->decode(do { local $/; <$rf> });
close $rf;

my $results = (values %$idx)[0] || {};
my @failed = grep {
    my $b = $results->{$_}{behavior} // '';
    $b eq 'FAILED' || $b eq 'UNIMPLEMENTED' || $b eq 'WRONG CODE'
} sort keys %$results;

ok(scalar(keys %$results) > 0, "autobahn ran cases (" . scalar(keys %$results) . ")");
is(scalar(@failed), 0, "no failing autobahn cases")
    or diag "failing cases: @failed";

done_testing;
