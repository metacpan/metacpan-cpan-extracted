use strict;
use warnings;
use Test::More qw( no_plan );
use MARC::Field;

use_ok( 'MARC::Detrans::Names' );
use_ok( 'MARC::Detrans::Name' );

my $names = MARC::Detrans::Names->new();
isa_ok( $names, 'MARC::Detrans::Names' );

my $name = MARC::Detrans::Name->new(
    from => '$aNicholas $bI, $cEmperor of Russia, $d1796-1855',
    to   => '$a^[(NnIKOLAJ^[s, $bI, $c^[(NiMPERATOR^[s ^[(NwSEROSSIJSKIJ^[s, $d1796-1855' 
);
isa_ok( $name, 'MARC::Detrans::Name' );

$names->addName( $name );

my $field = MARC::Field->new( '100', '', '', 
    a   => 'Nicholas ',
    b   => 'I, ',
    c   => 'Emperor of Russia, ',
    d   => '1796-1855'
);

my $new = $names->convert( $field );
ok( ref($new) eq 'ARRAY', 'convert() returned an array ref' );
is_deeply( $new, [ a => '^[(NnIKOLAJ^[s, ', b =>'I, ', c => '^[(NiMPERATOR^[s ^[(NwSEROSSIJSKIJ^[s, ', d => '1796-1855' ] );

