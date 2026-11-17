#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::mysql;
use Time::HiRes qw(time);

my $m = EV::mysql->new(
    host     => $ENV{TEST_MYSQL_HOST} // '127.0.0.1',
    port     => $ENV{TEST_MYSQL_PORT} // 3306,
    user     => $ENV{TEST_MYSQL_USER} // 'root',
    password => $ENV{TEST_MYSQL_PASS} // '',
    database => $ENV{TEST_MYSQL_DB}   // 'test',
    ($ENV{TEST_MYSQL_SOCKET} ? (unix_socket => $ENV{TEST_MYSQL_SOCKET}) : ()),
    on_connect => sub { print "connected\n" },
    on_error   => sub { die "connection error: $_[0]\n" },
);

my $N = 200;
my $done = 0;
my @results;
my $t0 = time;

# queue N queries without waiting -- EV::mysql executes them in FIFO order
for my $i (1 .. $N) {
    $m->query("select $i as n", sub {
        my ($rows, $err) = @_;
        die "query $i: $err\n" if $err;
        push @results, $rows->[0][0];

        if (++$done == $N) {
            my $elapsed = time - $t0 || 1e-6;
            printf "completed %d pipelined queries in %.3fs (%.0f q/s)\n",
                $N, $elapsed, $N / $elapsed;

            # verify FIFO ordering
            my $ok = 1;
            for my $j (0 .. $#results) {
                if ($results[$j] != $j + 1) { $ok = 0; last }
            }
            print $ok ? "order: correct\n" : "order: WRONG\n";
            $m->close_async(sub { EV::break });
        }
    });
}

print "pending after submit: ", $m->pending_count, "\n";
EV::run;
