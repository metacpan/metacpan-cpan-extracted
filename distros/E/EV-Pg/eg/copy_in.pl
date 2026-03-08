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
        $pg->query("create temp table people (id int, name text)", sub {
            my (undef, $err) = @_;
            die $err if $err;

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

                die $err if $err;
                print "copied $data rows\n";

                # verify
                $pg->query("select * from people order by id", sub {
                    my ($rows, $err) = @_;
                    die $err if $err;
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
