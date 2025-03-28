#!/usr/bin/perl
use 5.012;
use strict;
use warnings;
use Test::Lib;
use File::Spec;
use Test::More tests => 9;
use Test::Map::Tube;
use Sample;

my %tests = (
              'good-map.xml'                             => undef, # supposed to pass
              'station-other-link.xml'                   => undef, # supposed to pass
              'station-linked-share-no-line.xml'         => 'Stations id A1 and A2 are linked but share no line',                       # supposed to fail
              'station-line-not-linking.xml'             => 'Line id B at station id A1 serves neither a linked nor a linking station', # supposed to fail
              'station-line-not-linking-at-terminal.xml' => undef, # supposed to pass
              'station-other-link-not-linking.xml'       => 'Stations id A1 and B2 are linked but share no line',                       # supposed to fail
            );

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

for my $name ( sort keys %tests ) {
    my $dataname = File::Spec->catfile( @localdir, $name );
    my $map = Sample->new( xml => $dataname );

    my( $ok, @messages ) = ok_stations_linked_share_lines( $map, { name => $name } );
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

