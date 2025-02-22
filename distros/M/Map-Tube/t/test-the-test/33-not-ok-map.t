#!/usr/bin/perl
use 5.012;
use strict;
use warnings;
use Test::Lib;
use File::Spec;
use Test::More tests => 6;
use Test::Map::Tube;
use Sample;

my %tests = (
               'good-map.xml'             => 'No errors found in map data for good-map.xml', # supposed to fail
               'station-names-prefix.xml' => undef, # supposed to pass
               'map-unconnected.xml'      => 'No errors found in map data for map-unconnected.xml', # would be supposed to fail, but we don't perform this check here
            );

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

for my $name ( sort keys %tests ) {
    my $dataname = File::Spec->catfile( @localdir, $name );
    my $map = Sample->new( xml => $dataname );

    my( $ok, @messages ) = not_ok_map( $map,
                                      { name => $name,
                                        ok_station_names_complete => 1,
                                        ok_map_connected => undef,
                                      },
                                    );
    if ( $tests{$name} ) {
        # Expected to fail with a certain message:
        if ($ok) {
            # Unexpectedly passed the test when we shouldn't
            diag('Test passed although it should not, expected ' . $tests{$name} );
            ok( !$ok, $name );
        } else {
            # We failed as expected. Check whether we failed for the right reason.
            Test::More->builder()->no_diag(1);
            is( $messages[0], $tests{$name}, $name );
        }
    } else {
        # Expected to pass the test.
        diag($_) for @messages;
        ok( $ok, $name );
    }
}

