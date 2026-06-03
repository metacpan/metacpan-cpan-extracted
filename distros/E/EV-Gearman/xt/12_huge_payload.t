# Huge payloads exercise the buffer-grow paths. The 12-byte header's
# data_len field tops out at 4 GiB; this test makes sure our growth
# strategy scales without integer overflow or truncation.
#
# Verifies integrity via MD5 instead of shipping the payload back.
#
# Memory note: client and worker share this one process, so a payload
# of N bytes is resident several times over (client wbuf, worker rbuf,
# worker workload SV) and the buffers don't shrink afterwards. The
# default size is kept modest for that reason; set XT_HUGE=1 (or
# HUGE_MB=<n>) to push the real 64/128 MiB sizes on a roomy box.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use Digest::MD5 qw(md5_hex);
use EV;
use EV::Gearman;

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;
my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port, Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

# Build $size bytes of deterministic, non-uniform data via the string
# repeat operator. `map chr(...), 1..$size` would materialize a list
# of $size SVs first (~2.5 GiB at 64 MiB) and OOM the box — the repeat
# of a small block never does.
sub make_payload {
    my ($size) = @_;
    my $block = join '', map chr($_ % 251), 0 .. 1023;   # 1 KiB, non-uniform
    my $p = $block x int($size / length $block);
    $p .= substr $block, 0, $size - length $p;
    $p;
}

my $cli = EV::Gearman->new(host => $host, port => $port);
my $wkr = EV::Gearman->new(host => $host, port => $port);
$wkr->register_function('huge_'.$$ => sub {
    my $w = $_[0]->workload;
    return md5_hex($w) . ':' . length($w);
});
$wkr->work;

sub roundtrip {
    my ($size, $why) = @_;
    diag "preparing $why ($size bytes)";
    my $payload = make_payload($size);
    my $expected = md5_hex($payload) . ':' . length($payload);

    my ($got, $err);
    $cli->submit_job('huge_'.$$, $payload, sub {
        ($got, $err) = @_; EV::break;
    });
    # Drop the test's own copy now that it's queued in the client's
    # write buffer — keeps only the in-flight copies resident.
    undef $payload;
    my $guard = EV::timer 120, 0, sub { fail "$why timeout"; EV::break };
    EV::run;

    is $err, undef, "$why: no error";
    is $got, $expected, "$why: integrity OK";
}

# Base size in MiB (default 32 — large enough for ~11 buffer doublings
# off the 16 KiB init size, small enough not to OOM a shared box).
my $base = $ENV{HUGE_MB} || 32;
roundtrip $base * 1024 * 1024, "${base} MiB";

if ($ENV{XT_HUGE}) {
    roundtrip 64  * 1024 * 1024, '64 MiB';
    roundtrip 128 * 1024 * 1024, '128 MiB';
} else {
    diag 'set XT_HUGE=1 to also test 64 + 128 MiB';
}

done_testing;
