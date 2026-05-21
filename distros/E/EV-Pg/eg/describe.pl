#!/usr/bin/env perl
use strict;
use warnings;
use EV;
use EV::Pg;

# Demonstrates describe_prepared.  Unlike most callbacks, describe
# delivers a hashref of metadata: nfields, nparams, fields (when
# nfields > 0), paramtypes (when nparams > 0).

my $conninfo = shift || $ENV{TEST_PG_CONNINFO} || 'dbname=postgres';

my $pg; $pg = EV::Pg->new(
    conninfo => $conninfo,
    on_error => sub { die "connection error: $_[0]\n" },
    on_connect => sub {
        $pg->prepare('demo', 'select $1::int as n, $2::text as label, now() as ts',
            sub {
                my (undef, $err) = @_; die $err if $err;

                $pg->describe_prepared('demo', sub {
                    my ($meta, $err) = @_; die $err if $err;

                    print "nparams: $meta->{nparams}\n";
                    print "param types (OIDs):\n";
                    print "  $_\n" for @{ $meta->{paramtypes} };

                    print "nfields: $meta->{nfields}\n";
                    print "columns:\n";
                    for my $f (@{ $meta->{fields} }) {
                        printf "  %-10s type OID %d\n", $f->{name}, $f->{type};
                    }

                    EV::break;
                });
            });
    },
);

EV::run;
