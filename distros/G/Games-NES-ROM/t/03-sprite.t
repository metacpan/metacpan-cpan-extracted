use strict;
use warnings;

use Test::More tests => 13;

use_ok( 'Games::NES::ROM' );

my $rom = Games::NES::ROM->load( 't/roms/test.nes' );
isa_ok( $rom, 'Games::NES::ROM' );

my $sprite = $rom->sprite( 0, 0 );
ok( $sprite );
is( length( $sprite ), 64 );

my $expected = [
    0, 0, 0, 0, 0, 0, 1, 1,
    0, 0, 0, 0, 1, 1, 1, 1,
    0, 0, 0, 1, 1, 1, 1, 1,
    0, 0, 0, 1, 1, 1, 1, 1,
    0, 0, 0, 3, 3, 3, 2, 2,
    0, 0, 3, 2, 2, 3, 2, 2,
    0, 0, 3, 2, 2, 3, 3, 2,
    0, 3, 3, 2, 2, 3, 3, 2
];

is( $sprite, join( '', pack( 'C*', @$expected ) ) );

eval { $rom->sprite( -1, 0 ); };
ok( $@ );
like( $@, qr/invalid CHR bank/ );

eval { $rom->sprite( 2, 0 ); };
ok( $@ );
like( $@, qr/invalid CHR bank/ );

eval { $rom->sprite( 0, -1 ); };
ok( $@ );
like( $@, qr/invalid sprite index/ );

eval { $rom->sprite( 0, 513 ); };
ok( $@ );
like( $@, qr/invalid sprite index/ );
