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
        $pg->enter_pipeline;

        # batch 100 queries without waiting for individual results
        my @results;
        for my $i (1 .. 100) {
            $pg->query_params('select $1::int * $1::int', [$i], sub {
                my ($rows, $err) = @_;
                die $err if $err;
                push @results, $rows->[0][0];
            });
        }

        $pg->pipeline_sync(sub {
            $pg->exit_pipeline;
            print "received ", scalar @results, " results\n";
            print "1^2=", $results[0], " 100^2=", $results[-1], "\n";
            EV::break;
        });
    },
);

EV::run;
