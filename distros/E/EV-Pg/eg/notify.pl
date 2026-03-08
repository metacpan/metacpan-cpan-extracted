#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Pg;

my $conninfo = shift || $ENV{TEST_PG_CONNINFO} || 'dbname=postgres';

my $pg; $pg = EV::Pg->new(
    conninfo => $conninfo,
    on_error  => sub { die "connection error: $_[0]\n" },
    on_notify => sub {
        my ($channel, $payload, $pid) = @_;
        print "notification on '$channel': $payload (from pid $pid)\n";
        EV::break;
    },
    on_connect => sub {
        $pg->query("listen my_channel", sub {
            my (undef, $err) = @_;
            die $err if $err;
            print "listening on my_channel, sending test notification...\n";

            $pg->query("notify my_channel, 'hello from EV::Pg'", sub {
                my (undef, $err) = @_;
                die $err if $err;
            });
        });
    },
);

EV::run;
