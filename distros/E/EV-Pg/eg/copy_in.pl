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
        $pg->query("create temp table people (id int, name text)", sub {
            my (undef, $err) = @_;
            if ($err) { warn $err; EV::break; return; }

            $pg->query("copy people from stdin", sub {
                my ($data, $err) = @_;

                if (($data // '') eq 'COPY_IN') {
                    # send tab-delimited rows
                    $pg->put_copy_data("1\tAlice\n");
                    $pg->put_copy_data("2\tBob\n");
                    $pg->put_copy_data("3\tCharlie\n");
                    $pg->put_copy_end;
                    return;
                }

                if ($err) { warn $err; EV::break; return; }
                print "copied $data rows\n";

                # verify
                $pg->query("select * from people order by id", sub {
                    my ($rows, $err) = @_;
                    if ($err) { warn $err; EV::break; return; }
                    for my $row (@$rows) {
                        print "  $row->[0]: $row->[1]\n";
                    }
                    EV::break;
                });
            });
        });
    },
);

EV::run;
