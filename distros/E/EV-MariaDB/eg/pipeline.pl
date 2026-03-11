#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::MariaDB;
use Time::HiRes qw(time);

my $m = EV::MariaDB->new(
    host     => $ENV{TEST_MARIADB_HOST} // '127.0.0.1',
    port     => $ENV{TEST_MARIADB_PORT} // 3306,
    user     => $ENV{TEST_MARIADB_USER} // 'root',
    password => $ENV{TEST_MARIADB_PASS} // '',
    database => $ENV{TEST_MARIADB_DB}   // 'test',
    ($ENV{TEST_MARIADB_SOCKET} ? (unix_socket => $ENV{TEST_MARIADB_SOCKET}) : ()),
    on_connect => sub { print "connected\n" },
    on_error   => sub { die "connection error: $_[0]\n" },
);

my $N = 200;
my $done = 0;
my @results;
my $t0 = time;

# fire N queries without waiting — they pipeline automatically
for my $i (1 .. $N) {
    $m->query("SELECT $i AS n", sub {
        my ($rows, $err) = @_;
        die "query $i: $err\n" if $err;
        push @results, $rows->[0][0];

        if (++$done == $N) {
            my $elapsed = time - $t0;
            printf "completed %d pipelined queries in %.3fs (%.0f q/s)\n",
                $N, $elapsed, $N / $elapsed;

            # verify FIFO ordering
            my $ok = 1;
            for my $j (0 .. $#results) {
                if ($results[$j] != $j + 1) { $ok = 0; last }
            }
            print $ok ? "order: correct\n" : "order: WRONG\n";
            EV::break;
        }
    });
}

print "pending after submit: ", $m->pending_count, "\n";
EV::run;
