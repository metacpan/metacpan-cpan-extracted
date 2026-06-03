# Large payload edge cases.
# Gearman puts the workload last in the packet; the 4-byte length
# field caps it at 4 GB, but in practice gearmand has its own
# limits and your sockets are small. This test runs payloads at
# 1 MiB, 8 MiB, and 32 MiB to verify the read/write buffer growth
# code path doesn't truncate, double-buffer, or run out of capacity.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::Gearman;
use Digest::MD5 qw(md5_hex);

my $host = $ENV{TEST_GEARMAN_HOST} || '127.0.0.1';
my $port = $ENV{TEST_GEARMAN_PORT} || 4730;

my $probe = IO::Socket::INET->new(
    PeerAddr => $host, PeerPort => $port,
    Proto => 'tcp', Timeout => 1,
);
plan skip_all => "no gearmand at $host:$port" unless $probe;
close $probe;

my $cli = EV::Gearman->new(host => $host, port => $port);
my $wkr = EV::Gearman->new(host => $host, port => $port);

# Echo back length+md5 so we can verify integrity without shipping
# the payload twice over the wire.
$wkr->register_function('xt_big_'.$$ => sub {
    my $w = $_[0]->workload;
    return md5_hex($w) . ':' . length($w);
});
$wkr->work;

# Build $size bytes via the string-repeat operator. The obvious
# `join '', map chr(...), 1..$size` first materializes a list of $size
# SVs (hundreds of MiB to GiB), so build from a small repeated block.
sub make_payload {
    my ($size) = @_;
    my $block = join '', map chr(ord('A') + $_ % 26), 0 .. 1023;
    my $p = $block x int($size / length $block);
    $p .= substr $block, 0, $size - length $p;
    $p;
}

sub run_size {
    my ($size, $why) = @_;
    my $payload = make_payload($size);
    my $expected = md5_hex($payload) . ':' . length($payload);

    my ($got, $err);
    $cli->submit_job('xt_big_'.$$, $payload, sub {
        ($got, $err) = @_; EV::break;
    });
    undef $payload;
    my $guard = EV::timer 60, 0, sub { fail "$why timeout"; EV::break };
    EV::run;

    is $err, undef, "$why: no error";
    is $got, $expected, "$why: payload integrity OK ($size bytes)";
}

run_size 1024 * 1024,        '1 MiB';
run_size 8  * 1024 * 1024,   '8 MiB';

if ($ENV{XT_HUGE}) {
    run_size 32 * 1024 * 1024, '32 MiB';
} else {
    diag 'set XT_HUGE=1 to also test 32 MiB';
}

done_testing;
