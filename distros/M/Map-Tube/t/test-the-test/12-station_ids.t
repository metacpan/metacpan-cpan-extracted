#!/usr/bin/perl
use 5.012;
use strict;
use warnings;
use Test::Lib;
use File::Spec;
use Test::More tests => 4;
use Test::Map::Tube;
use Sample;

my %tests = (
              'good-map.xml'            => undef, # supposed to pass
              'station-id-invalid1.xml' => "Station ID 'A,1' must not contain comma (,) or colon (:)", # supposed to fail
              'station-id-invalid2.xml' => "Station ID 'B:2' must not contain comma (,) or colon (:)", # supposed to fail
            );

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

for my $name ( sort keys %tests ) {
    my $dataname = File::Spec->catfile( @localdir, $name );
    my $map = Sample->new( xml => $dataname );

    my( $ok, @messages ) = ok_station_ids( $map, { name => $name } );
    if ( $tests{$name} ) {
        # Expected to fail with a certain message:
        if ($ok) {
            # Unexpectedly passed the test when we shouldn't
            diag('Test passed although it should not, expected ' . $tests{$name} );
            ok( !$ok, $name );
        } else {
            # We failed as expected. Check whether we failed for the right reason.
            is( $messages[0], $tests{$name}, $name );
        }
    } else {
        # Expected to pass the test.
        diag($_) for @messages;
        ok( $ok, $name );
    }
}

