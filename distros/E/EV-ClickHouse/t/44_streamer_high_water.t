#!/usr/bin/env perl
# Push above high_water; verify on_high_water fires and await_drain
# wakes once the buffer drops back to low_water.
use strict;
use warnings;
use Test::More;
use IO::Socket::INET;
use EV;
use EV::ClickHouse;

my $host  = $ENV{TEST_CLICKHOUSE_HOST}        || '127.0.0.1';
my $nport = $ENV{TEST_CLICKHOUSE_NATIVE_PORT} || 9000;

plan skip_all => "ClickHouse native not reachable"
    unless IO::Socket::INET->new(PeerAddr => $host, PeerPort => $nport, Timeout => 2);

plan tests => 5;

my $tbl  = "ev_ch_hw_$$";
my $err;
my $hw_calls = 0;
my $drain_calls = 0;
my $total = 0;
my $final_count;

my $ch; $ch = EV::ClickHouse->new(
    host => $host, port => $nport, protocol => 'native',
    on_connect => sub {
        $ch->query("create table $tbl (n UInt32) engine=Memory", sub {
            my (undef, $e) = @_; $err = $e and return EV::break;
            my $s; $s = $ch->insert_streamer($tbl,
                batch_size    => 1_000,
                high_water    => 3_000,
                low_water     => 1_000,
                on_high_water => sub {
                    $hw_calls++;
                    # First time we hit the watermark, register a drain wake-up.
                    return unless $hw_calls == 1;
                    $s->await_drain(sub {
                        $drain_calls++;
                        # Push the remaining rows and finish.
                        for my $n (($total + 1) .. 6_000) {
                            $s->push_row([$n]);
                            $total++;
                        }
                        $s->finish(sub {
                            my (undef, $e) = @_; $err = $e;
                            $ch->query("select count() from $tbl", sub {
                                my ($r, $e) = @_;
                                $err //= $e;
                                $final_count = $r ? $r->[0][0] : undef;
                                $ch->query("drop table $tbl", sub {
                                    EV::break;
                                });
                            });
                        });
                    });
                },
            );
            # Push 6k rows synchronously; on_high_water should fire as we
            # cross 3000, after which we wait for await_drain before
            # pushing the remainder (in the on_high_water callback).
            for (1 .. 6_000) {
                last if $hw_calls;
                $s->push_row([$_]);
                $total++;
            }
        });
    },
    on_error => sub { $err = $_[0]; EV::break },
);

my $bail = EV::timer(15, 0, sub { EV::break }); EV::run; undef $bail;
$ch->finish;

ok !$err,                          "no error" or diag $err;
ok $hw_calls > 0,                  "on_high_water fired at least once";
is $hw_calls, 1,                   "on_high_water re-armed (not re-fired during the burst)";
ok $drain_calls > 0,               "await_drain woke after buffer dropped";
is $final_count, 6_000,            "all 6000 rows landed";
