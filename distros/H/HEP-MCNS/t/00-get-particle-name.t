use Test::Simple tests => 3;

use HEP::MCNS 'particle_name';

# 999 is not a particle code --> sub should return the given argument
# this is the only special case, for everything else is just hash-lookup for now
ok( particle_name( 999 ) eq "999", 'unknown particle' );

# for completeness
ok( particle_name( 521 ) eq 'B+', 'B+ meson' );
ok( particle_name( -521 ) eq 'B-', 'B- meson' );
