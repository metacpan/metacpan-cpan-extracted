#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;

for my $m ( qw(Map::Tube::London Text::Soundex Text::Unidecode) ) {
  eval "use $m";
  plan skip_all => "$m required for this test" if $@;
}
# Actually, Text::Unidecode is not required by ourselves, but rather
# by Text::Soundex::unidecode. However, there is no check for that
# in Text::Soundex (as of 3.04).

plan tests => 18;

sub a2n { return [ map { $_->name() } @{ $_[0] } ]; }

my $tube = new_ok( 'Map::Tube::London' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'soundex' );
is( $ret, 'Bakerloo', 'Finding line Bakerloo based on soundex' );

$ret = $tube->fuzzy_find( 'Bkrl', objects => 'lines', method => 'soundex' );
is( $ret, 'Bakerloo', 'Finding line Bkrl based on soundex' );

$ret = $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'soundex' );
is( $ret, undef, 'Finding line Bxqxq based on soundex should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'soundex' ) ];
is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo based on soundex' );

$ret = [ $tube->fuzzy_find( 'Bkrl', objects => 'lines', method => 'soundex' ) ];
is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bkrl based on soundex' );

$ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'soundex' ) ];
is_deeply( $ret, [ ], 'Finding many lines Bxqxq based on soundex should fail' );

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'soundex' );
ok( $ret, 'Finding station Baker Street based on soundex' );
is( $ret->name(), 'Baker Street', 'Finding station Baker Street based on soundex' );

$ret = $tube->fuzzy_find( 'Bkrs', objects => 'stations', method => 'soundex' );
ok( $ret, 'Finding station Bkrs based on soundex' );
is( $ret->name(), 'Baker Street', 'Finding station Bkrs based on soundex' );

$ret = $tube->fuzzy_find( 'Bxqxq', objects => 'stations', method => 'soundex' );
ok( $ret, 'Finding station Bxqxq based on soundex' );
is( $ret->name(), 'Bushey', 'Finding station Bxqxq based on soundex' );

$ret = $tube->fuzzy_find( 'Pxqxq', objects => 'stations', method => 'soundex' );
is( $ret, undef, 'Finding station Pxqxq based on soundex should fail' );

$ret = [ $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'soundex' ) ];
is_deeply( a2n($ret), [ 'Baker Street', 'Bow Church', 'Buckhurst Hill' ], 'Finding many stations Baker Street based on soundex' );

$ret = [ $tube->fuzzy_find( 'Bkrs', objects => 'stations', method => 'soundex' ) ];
is_deeply( a2n($ret), [ 'Baker Street', 'Bow Church', 'Buckhurst Hill' ], 'Finding many stations Bkrs based on soundex' );

$ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'stations', method => 'soundex' ) ];
is_deeply( a2n($ret), [ 'Bushey' ], 'Finding many stations Bxqxq based on soundex' );

$ret = [ $tube->fuzzy_find( 'Pxqxq', objects => 'stations', method => 'soundex' ) ];
is_deeply( $ret, [ ], 'Finding many stations Pxqxq based on soundex should fail' );

