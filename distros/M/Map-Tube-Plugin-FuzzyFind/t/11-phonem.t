#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
use lib 't/';
use Sample;

eval 'use Text::Phonetic::Phonem';
plan skip_all => 'Text::Phonetic::Phonem required for this test' if $@;

plan tests => 14;

sub a2n { return [ map { $_->name( ) } @{ $_[0] } ]; }

my $tube = new_ok( 'Sample' );
my $ret;

$ret = $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'phonem' );
is( $ret, 'Bakerloo', 'Finding line Bakerloo based on Phonem' );

$ret = $tube->fuzzy_find( 'Bakrloh', objects => 'lines', method => 'phonem' );
is( $ret, 'Bakerloo', 'Finding line Bakrloh based on Phonem' );

$ret = $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'phonem' );
is( $ret, undef, 'Finding line Bxqxq based on Phonem should fail' );

$ret = [ $tube->fuzzy_find( 'Bakerloo', objects => 'lines', method => 'phonem' ) ];
is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bakerloo based on Phonem' );

$ret = [ $tube->fuzzy_find( 'Bakrloh', objects => 'lines', method => 'phonem' ) ];
is_deeply( $ret, [ 'Bakerloo' ], 'Finding many lines Bakrloh based on Phonem' );

$ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'lines', method => 'phonem' ) ];
is_deeply( $ret, [ ], 'Finding many lines Bxqxq based on Phonem should fail' );

$ret = $tube->fuzzy_find( 'Baker Street', objects => 'stations', method => 'phonem' );
ok( $ret, 'Finding station Baker Street based on Phonem' );
is( $ret->name(), 'Baker Street', 'Finding station Baker Street based on Phonem' );

$ret = $tube->fuzzy_find( 'Bakrstrt', objects => 'stations', method => 'phonem' );
ok( $ret, 'Finding station Bakestrt based on Phonem' );
is( $ret->name(), 'Baker Street', 'Finding station Bakestrt based on Phonem' );

$ret = $tube->fuzzy_find( 'Bxqxq', objects => 'stations', method => 'phonem' );
is( $ret, undef, 'Finding station Bxqxq based on Phonem should fail' );

$ret = [ $tube->fuzzy_find( 'Bakrstrt', objects => 'stations', method => 'phonem' ) ];
is_deeply( a2n($ret), [ 'Baker Street' ], 'Finding many stations Bakestrt based on Phonem' );

$ret = [ $tube->fuzzy_find( 'Bxqxq', objects => 'stations', method => 'phonem' ) ];
is_deeply( $ret, [ ], 'Finding many stations Bxqxq based on Phonem should fail' );

