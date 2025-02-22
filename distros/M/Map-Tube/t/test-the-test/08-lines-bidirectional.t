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
              'good-map.xml'             => undef, # supposed to pass
              'line1-unidirectional.xml' => 'Station id A1 linked to A2 but not vice versa via line(s) id A', # supposed to fail
              'line2-unidirectional.xml' => 'Station id A1 linked to A2 but not vice versa via line(s) id A', # supposed to fail
            );

my @localdir = File::Spec->splitdir($0);
pop(@localdir);

for my $name ( sort keys %tests ) {
    my $dataname = File::Spec->catfile( @localdir, $name );
    my $map = Sample->new( xml => $dataname );

    my( $ok, @messages ) = ok_links_bidirectional( $map, { name => $name } );
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

my $name     = 'line1-unidirectional.xml';
my $dataname = File::Spec->catfile( @localdir, $name );
my $map      = Sample->new( xml => $dataname );

my( $ok, @messages ) = ok_links_bidirectional( $map, { name => $name, exclude => "A" } );
diag($_) for @messages;
ok( $ok, $name );

$name     = 'line2-unidirectional.xml';
$dataname = File::Spec->catfile( @localdir, $name );
$map      = Sample->new( xml => $dataname );

( $ok, @messages ) = ok_links_bidirectional( $map, { name => $name, exclude => "A" } );
# Expected to fail with a certain message:
if ($ok) {
    # Unexpectedly passed the test when we shouldn't
    diag('Test passed although it should not, expected "Station id B1 linked to B2 but not vice versa via line(s) id B"' );
    ok( !$ok, $name );
} else {
    # We failed as expected. Check whether we failed for the right reason.
    is( $messages[0], 'Station id B1 linked to B2 but not vice versa via line(s) id B', $name );
}

( $ok, @messages ) = ok_links_bidirectional( $map, { name => $name, exclude => [ "A", "B" ] } );
diag($_) for @messages;
ok( $ok, $name );

