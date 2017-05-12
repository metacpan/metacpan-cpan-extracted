use Test::Simple tests => 4;

use HEP::MCNS 'particle_code';

# unknown particle should return 0 by definition
ok( particle_code( 'not-a-particle' ) == 0, 'unknown particle' );

# for completeness
ok( particle_code( 'B+' ) == 521, 'B+ meson' );
ok( particle_code( 'B-' ) == -521, 'B- meson' );
ok( particle_code( 'anti-b0' ) == -511, 'lowercase anti B0 meson' );
