#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Pg;

my $conninfo = shift || $ENV{TEST_PG_CONNINFO} || 'dbname=postgres';

my $pg; $pg = EV::Pg->new(
    conninfo => $conninfo,
    on_error => sub {
        warn "connection-level error: $_[0]\n";
        EV::break;
    },
    on_notice => sub {
        print "notice: $_[0]";
    },
    on_connect => sub {
        # query-level error: bad SQL
        $pg->query("select from nonexistent_table", sub {
            my ($rows, $err) = @_;
            if ($err) {
                print "query error (expected): $err\n";
            }

            # raise a notice
            $pg->query("do \$\$ begin raise notice 'this is a notice'; end \$\$", sub {
                my (undef, $err) = @_;
                die $err if $err;
                EV::break;
            });
        });
    },
);

EV::run;
