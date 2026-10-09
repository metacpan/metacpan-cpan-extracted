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
    on_error => sub { warn "connection error: $_[0]\n"; EV::break },
    on_connect => sub {
        $pg->query("create temp table nums (n int)", sub {
            my (undef, $err) = @_;
            if ($err) { warn $err; EV::break; return; }

            $pg->query("insert into nums select generate_series(1, 5)", sub {
                my ($n, $err) = @_;
                if ($err) { warn $err; EV::break; return; }
                print "inserted $n rows\n";

                # Note: this single callback fires twice -- once for
                # "COPY_OUT" (start), once for command_ok (done).
                $pg->query("copy nums to stdout", sub {
                    my ($data, $err) = @_;
                    if ($err) { warn $err; EV::break; return; }

                    if ($data eq 'COPY_OUT') {
                        # Drain the stream synchronously.  get_copy_data
                        # returns a row string, the integer -1 (stream
                        # complete), or undef (would block).  In an
                        # async program, return on undef: this callback
                        # fires again with "COPY_OUT" when more data arrives.
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
