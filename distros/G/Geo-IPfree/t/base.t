use strict;
use warnings;

use Test::More tests => 177;

use_ok('Geo::IPfree');

my @b86 = ( 0 .. 9, 'A' .. 'Z', 'a' .. 'z', split( m{}, q(.,;'"`<>{}[]=+-~*@#%$&!?) ) );

for ( 0 .. 85 ) {
    is( Geo::IPfree::dec2baseX($_),         sprintf( '%05s', $b86[$_] ), "dec2baseX( '$_' )" );
    is( Geo::IPfree::baseX2dec( $b86[$_] ), $_,                          "baseX2dec( '$b86[ $_ ]' )" );
}
is( Geo::IPfree::baseX2dec('AAAAA'), 553443550,  "Geo::IPfree::baseX2dec('AAAAA')" );
is( Geo::IPfree::baseX2dec('BBBBB'), 608787905,  "Geo::IPfree::baseX2dec('BBBBB')" );
is( Geo::IPfree::baseX2dec('CCCCC'), 664132260,  "Geo::IPfree::baseX2dec('CCCCC')" );
is( Geo::IPfree::baseX2dec('x4OYa'), 3230072832, "Geo::IPfree::baseX2dec('x4OYa')" );

