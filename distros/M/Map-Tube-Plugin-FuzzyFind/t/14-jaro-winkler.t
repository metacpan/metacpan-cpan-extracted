#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

eval 'use Map::Tube 3.77';
plan skip_all => 'Map::Tube (>= 3.77) required for this test' if $@;

eval 'use Map::Tube::London 1.39';
plan skip_all => 'Map::Tube::London (>= 1.39) required for this test' if $@;

eval 'use Text::JaroWinkler';
plan skip_all => 'Text::JaroWinkler required for this test' if $@;

plan tests => 26;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'jarowinkler' );
is( $ret, 'Bakerloo', 'Finding Bakerloo based on Jaro-Winkler' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'jarowinkler', maxdist => 5 );
is( $ret, 'Circle', 'Finding line Packalu based on Jaro-Winkler with distance 5');

$ret = $tube->fuzzy_find( 'Packxxx', objects => 'lines', method => 'jarowinkler' );
is( $ret, undef, 'Finding line Packxxx based on Jaro-Winkler with standard distance should fail' );

$ret = $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'jarowinkler', maxdist => 3 );
is( $ret, undef, 'Finding line Packalu based on Jaro-Winkler with distance 3 should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'jarowinkler', maxdist=>4 ) ];
is_deeply( $ret, [ 'Bakerloo', 'Waterloo and City' ], 'Finding many lines Bakerloo based on Jaro-Winkler' );

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'jarowinkler', maxdist => 5 ) ];
is_deeply( $ret, [ 'Circle', 'Bakerloo', 'Central', 'Piccadilly' ], 'Finding many lines Packalu based on Jaro-Winkler with distance 5' );

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'jarowinkler', maxdist => 4 ) ];
is_deeply( $ret, [ ], 'Finding many lines Packalu based on Jaro-Winkler with distance 4 should fail' );

$ret = [ $tube->fuzzy_find( 'Packalu', objects => 'lines', method => 'jarowinkler' ) ];
is_deeply( $ret, [ ], 'Finding many lines Packalu based on Jaro-Winkler with standard distance should fail' );

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'jarowinkler' );
ok( $ret, 'Finding station Baker Street based on Jaro-Winkler');
is( $ret->name(), 'Baker Street', 'Finding station Baker Street based on Jaro-Winkler' );

$ret = $tube->fuzzy_find( 'Baker', objects => 'stations', method => 'jarowinkler' );
ok( $ret, 'Finding station Baker based on Jaro-Winkler');
is( $ret->name(), 'Baker Street', 'Finding station Baker based on Jaro-Winkler' );

$ret = $tube->fuzzy_find( 'Paisvatr', objects => 'stations', method => 'jarowinkler' );
ok( $ret, 'Finding station Paisvatr based on Jaro-Winkler');
is( $ret->name(), 'Plaistow', 'Finding station Paisvatr based on Jaro-Winkler' );

$ret = $tube->fuzzy_find( 'Beisftr', objects => 'stations', method => 'jarowinkler', maxdist => 3 );
ok( $ret, 'Finding station Beisftr based on Jaro-Winkler with distance 3');
is( $ret->name(), 'Bayswater', 'Finding station Beisftr based on Jaro-Winkler at max distance 3' );

$ret = $tube->fuzzy_find( 'Qeixftr', objects => 'stations', method => 'jarowinkler' );
is( $ret, undef, 'Finding station Qeixftr based on Jaro-Winkler at standard max distance should fail' );

$ret = $tube->fuzzy_find( 'Beisftr', objects => 'stations', method => 'jarowinkler', maxdist => 1.5 );
is( $ret, undef, 'Finding station Beisftr based on Jaro-Winkler at max distance 4 should fail' );

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'jarowinkler', maxdist => 3 ) ];
is_deeply( a2n($ret), [ 'Baker Street', 'Turkey Street', 'Bank' ], 'Finding many stations Baker Street based on Jaro-Winkler at max distance 4' );

$ret = [ $tube->fuzzy_find( 'Baqer', objects => 'stations', method => 'jarowinkler' ) ];
is_deeply( a2n($ret), [ 'Baker Street', 'Barbican', 'Barking', 'Becontree' ], 'Finding many stations Baker based on Jaro-Winkler' );

$ret = [ $tube->fuzzy_find( 'Paisvatr', objects => 'stations', method => 'jarowinkler' ) ];
is_deeply( a2n($ret), [ 'Plaistow', 'Bayswater', 'Upminster' ], 'Finding many stations Paisvatr based on Jaro-Winkler' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'jarowinkler', maxdist => 4 ) ];
is_deeply( a2n($ret), [ 'Becontree', 'Bond Street' ], 'Finding many stations Bxxtree based on Jaro-Winkler at max distance 4' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'jarowinkler', maxdist => 4.5) ];
is_deeply( a2n($ret), [ 'Becontree', 'Bond Street', 'Baker Street', 'Old Street' ], 'Finding many stations Bxxtree based on Jaro-Winkler at max distance 4.5' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'jarowinkler' ) ];
is_deeply( a2n($ret), [ 'Becontree', 'Bond Street' ], 'Finding many stations Bxxtree based on Jaro-Winkler at standard max distance' );

$ret = [ $tube->fuzzy_find( 'Bxxtree', objects => 'stations', method => 'jarowinkler', maxdist => 2 ) ];
is_deeply($ret, [ ], 'Finding many stations Bxxtree based on Jaro-Winkler at max distance 2 should fail' );

