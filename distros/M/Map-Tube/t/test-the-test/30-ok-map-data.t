#!/usr/bin/perl
use 5.012;
use strict;
use warnings;
use Test::Lib;
use File::Spec;
use Test::More tests => 8;
use Test::Map::Tube;
use Sample;

my %tests = (
              'good-map.xml'             => undef, # supposed to pass
              'station-names-prefix.xml' => 'Incomplete name? :Station:Station A1:', # supposed to fail
              'map-unconnected.xml'      => undef, # would be supposed to fail, but we don't perform this check here
            );

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

for my $name ( sort keys %tests ) {
    my $dataname = File::Spec->catfile( @localdir, $name );
    my $map = Sample->new( xml => $dataname );

    my( $ok, @messages ) = ok_map( $map,
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
            is( $messages[1], $tests{$name}, $name );
        }
    } else {
        # Expected to pass the test.
        diag($_) for @messages;
        ok( $ok, $name );
    }
}

my $name = 'station-names-prefix.xml';
my $dataname = File::Spec->catfile( @localdir, $name );
my $map = Sample->new( xml => $dataname );

my( $ok, @messages ) = ok_map( $map,
                               { name => $name,
                                 ok_station_names_complete => { max_allowed => 1 },    # This should make the test pass
                                 ok_map_connected => undef,
                               },
                             );
diag($_) for @messages;
ok( $ok, $name );

