#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Pg;

my $conninfo = shift || $ENV{TEST_PG_CONNINFO} || 'dbname=postgres';

my $pg; $pg = EV::Pg->new(
    conninfo => $conninfo,
    on_error => sub { die "connection error: $_[0]\n" },
    on_connect => sub {
        # single-row mode: callback fires once per row, then
        # a final time with an empty arrayref
        my $count = 0;
        $pg->query("select n, n * n as square from generate_series(1, 5) n", sub {
            my ($rows, $err) = @_;
            die $err if $err;

            if (@$rows) {
                $count++;
                printf "row %d: n=%s square=%s\n", $count, $rows->[0][0], $rows->[0][1];
                return;
            }

            # final callback (empty result)
            print "total: $count rows\n";
            EV::break;
        });
        $pg->set_single_row_mode;
    },
);

EV::run;
