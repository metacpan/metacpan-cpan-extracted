#!/usr/bin/env perl
# Fan out N independent ClickHouse connections under a single EV loop.
# Each connection runs a query in parallel; the program exits once all N
# queries return.
use strict;
use warnings;
use EV;
use EV::ClickHouse;

my $host  = $ENV{CLICKHOUSE_HOST} // '127.0.0.1';
my $port  = $ENV{CLICKHOUSE_NATIVE_PORT} // 9000;
my $N     = 8;
my @pool;
my $left  = $N;

for my $i (1 .. $N) {
    my $ch;
    $ch = EV::ClickHouse->new(
        host       => $host,
        port       => $port,
        protocol   => 'native',
        on_connect => sub {
            $ch->query("select $i, count() from numbers(1_000_000)", sub {
                my ($rows, $err) = @_;
                if ($err) {
                    warn "[$i] err: $err\n";
                } else {
                    printf "[%d] count=%d\n", $i, $rows->[0][1];
                }
                EV::break unless --$left;
            });
        },
        on_error => sub { warn "[$i] connect err: $_[0]\n"; EV::break unless --$left },
    );
    push @pool, $ch;
}

EV::run;
$_->finish for grep { $_->is_connected } @pool;
