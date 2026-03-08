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
        # prepare once, execute many times
        $pg->prepare('get_square', 'select $1::int, ($1::int * $1::int) as square', sub {
            my (undef, $err) = @_;
            die $err if $err;

            # use pipeline mode to execute in batch
            $pg->enter_pipeline;

            my @values = (2, 5, 9, 12);

            for my $n (@values) {
                $pg->query_prepared('get_square', [$n], sub {
                    my ($rows, $err) = @_;
                    die $err if $err;
                    printf "%2d^2 = %3d\n", $rows->[0][0], $rows->[0][1];
                });
            }

            $pg->pipeline_sync(sub {
                $pg->exit_pipeline;
                EV::break;
            });
            $pg->send_flush_request;
        });
    },
);

EV::run;
