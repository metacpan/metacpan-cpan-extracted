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
        # parameterized queries prevent SQL injection
        $pg->query_params(
            'select $1::text || $2::text as greeting, $3::int * 2 as doubled',
            ['hello ', 'world', 21],
            sub {
                my ($rows, $err) = @_;
                die $err if $err;
                print "greeting: $rows->[0][0]\n";  # hello world
                print "doubled:  $rows->[0][1]\n";   # 42
                EV::break;
            },
        );
    },
);

EV::run;
