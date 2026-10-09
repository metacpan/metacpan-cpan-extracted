#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Pg;

my $conninfo = shift || $ENV{TEST_PG_CONNINFO} || 'dbname=postgres';

my $pg; $pg = EV::Pg->new(
    conninfo => $conninfo,
    on_error => sub { warn "connection error: $_[0]\n"; EV::break },
    on_connect => sub {
        print "connected to PostgreSQL\n";

        $pg->query("select version()", sub {
            my ($rows, $err) = @_;
            if ($err) { warn $err; EV::break; return; }
            print "server: $rows->[0][0]\n";
            EV::break;
        });
    },
);

EV::run;
