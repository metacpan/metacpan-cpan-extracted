#!perl
use 5.14.0;
use strict;
use warnings FATAL => 'all';
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More tests => 4;

BEGIN { use_ok('Map::Tube::Beijing') || print "Bail out!\n"; }

diag( "Testing Map::Tube::Beijing $Map::Tube::Beijing::VERSION, Perl $], $^X" );

my $map = Map::Tube::Beijing->new( );
isa_ok( $map, 'Map::Tube::Beijing', 'Map::Tube::Beijing object for pinyin' );

$map = Map::Tube::Beijing->new( nametype => 'alt' );
isa_ok( $map, 'Map::Tube::Beijing', 'Map::Tube::Beijing object for simplified Chinese script' );

eval { $map = Map::Tube::Beijing->new( nametype => 'XYZ' ); };
like($@, qr/\QMap::Tube::Beijing: ERROR: Invalid nametype for constructor: 'XYZ'\E/, 'Map::Tube::Beijing with non-existent nametype should not exist' );

