#!/usr/bin/env perl
# Drive a large chunked HTTP response through a proxy that dribbles the
# server->client direction in tiny writes, so the response is decoded across
# many read events. Guards the incremental chunked decoder: resuming at the
# wrong offset duplicates or drops a chunk, which shows up here as a wrong
# row count or wrong values (the old restart-from-scratch decoder was correct
# but quadratic, so this must stay correct while getting cheaper).
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use IO::Select;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST} || '127.0.0.1';
my $hport = $ENV{TEST_CLICKHOUSE_PORT} || 8123;

my $probe = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 2);
plan skip_all => "ClickHouse HTTP not reachable" unless $probe;
$probe->close;

plan tests => 4;

my $ROWS = 100_000;

# Proxy that forwards both ways but writes server->client in small pieces.
my $listener = IO::Socket::INET->new(
    Listen => 5, LocalAddr => '127.0.0.1', LocalPort => 0, ReuseAddr => 1,
) or die "listen: $!";
my $pport = $listener->sockport;

my $pid = fork;
die "fork: $!" unless defined $pid;
if ($pid == 0) {
    $SIG{PIPE} = 'IGNORE';
    while (my $client = $listener->accept) {
        my $up = IO::Socket::INET->new(PeerAddr => $host, PeerPort => $hport, Timeout => 5)
            or last;
        my $sel = IO::Select->new($client, $up);
        OUTER: while (my @ready = $sel->can_read(5)) {
            for my $fh (@ready) {
                my $buf;
                my $n = sysread($fh, $buf, 65536);
                last OUTER unless defined $n && $n > 0;
                if ($fh == $client) {
                    syswrite($up, $buf);
                } else {
                    # dribble downstream in 256-byte writes
                    while (length $buf) {
                        my $piece = substr($buf, 0, 256, '');
                        syswrite($client, $piece) or last OUTER;
                    }
                }
            }
        }
        close $client; close $up;
        last;
    }
    exit 0;
}

my ($rows, $err);
my $ch; $ch = EV::ClickHouse->new(
    host => '127.0.0.1', port => $pport, protocol => 'http',
    query_timeout => 60,
    on_connect => sub {
        $ch->query("SELECT number FROM numbers($ROWS) FORMAT TabSeparated", sub {
            ($rows, $err) = @_;
            EV::break;
        });
    },
    on_error => sub { $err //= $_[1] // 'connection error'; EV::break },
);
EV::run;

kill 'TERM', $pid; waitpid $pid, 0;

is($err, undef, 'trickled chunked response: no error')
    or diag("error: " . (defined $err ? $err : '(undef)'));
is(ref($rows) eq 'ARRAY' ? scalar(@$rows) : -1, $ROWS,
   "all $ROWS rows decoded across many read events");

my $bad = 0;
if (ref($rows) eq 'ARRAY' && @$rows == $ROWS) {
    for my $i (0, 1, int($ROWS / 2), $ROWS - 2, $ROWS - 1) {
        my $got = $rows->[$i][0];
        if (!defined $got || $got != $i) {
            $bad++;
            diag("row $i: expected $i, got " . (defined $got ? $got : 'undef'));
            last;
        }
    }
} else { $bad++ }
ok(!$bad, 'row values intact at start, middle and end (no duplicated/dropped chunk)');

# A duplicated chunk would keep the count wrong AND corrupt ordering; verify
# strict monotonicity over the whole body as a stronger integrity check.
my $mono = 1;
if (ref($rows) eq 'ARRAY' && @$rows == $ROWS) {
    for my $i (1 .. $#$rows) {
        if ($rows->[$i][0] != $rows->[$i - 1][0] + 1) { $mono = 0; diag("break at row $i"); last }
    }
} else { $mono = 0 }
ok($mono, 'body is strictly sequential end to end');
