#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Pg;

# Demonstrates the multi-phase COPY OUT callback protocol:
#   1. callback fires with ("COPY_OUT") -- streaming has begun
#   2. caller drains rows by looping get_copy_data until it returns -1
#   3. callback fires AGAIN with ($cmd_tuples) on completion

my $conninfo = shift || $ENV{TEST_PG_CONNINFO} || 'dbname=postgres';

my $pg; $pg = EV::Pg->new(
    conninfo => $conninfo,
    on_error => sub { die "connection error: $_[0]\n" },
    on_connect => sub {
        $pg->query("create temp table nums (n int)", sub {
            my (undef, $err) = @_; die $err if $err;

            $pg->query("insert into nums select generate_series(1, 5)", sub {
                my ($n, $err) = @_; die $err if $err;
                print "inserted $n rows\n";

                # Note: this single callback fires twice -- once for
                # "COPY_OUT" (start), once for command_ok (done).
                $pg->query("copy nums to stdout", sub {
                    my ($data, $err) = @_;
                    die $err if $err;

                    if ($data eq 'COPY_OUT') {
                        # Drain the stream synchronously.  get_copy_data
                        # returns a row string, the integer -1 (stream
                        # complete), or undef (would block).  In an
                        # async program you would re-enter the event
                        # loop on undef and resume on the next read.
                        while (1) {
                            my $line = $pg->get_copy_data;
                            last if !defined $line;        # would block
                            last if "$line" eq '-1';       # stream done
                            chomp $line;
                            print "row: $line\n";
                        }
                        return;
                    }

                    print "copy_out finished\n";
                    EV::break;
                });
            });
        });
    },
);

EV::run;
