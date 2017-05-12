#!perl
use strict; use warnings;
use Test::Most tests => 27;
use ok 'Device::WWN::HP::XP';

{
    ok(
        my $obj = Device::WWN::HP::XP->new( '50:6:e:80:4:ab:cd:0' ),
        "created object with wwn"
    );
    isa_ok( $obj, 'Device::WWN::HP::XP' );
    is( $obj->normalized, '50060e8004abcd00', 'normalized value OK' );
    is( $obj->oui->oui, '0060E8', 'oui value OK' );
    is( $obj->oui->norm, '00-60-E8', 'oui normalized value OK' );
    is( $obj->naa, 5, 'naa value OK' );
    is( $obj->vendor_id, '004abcd00', 'vendor_id value OK' );
    is( $obj->serial_number, '43981', 'serial_number value OK' );
    is( $obj->family_id, '04', 'family_id value OK' );
    is( $obj->port, '1A', 'port value OK' );
    is( $obj->family, 'XP12000/XP10000', 'family value OK' );
}

{
    ok(
        my $obj = Device::WWN::HP::XP->new( '50:06:0e:80:04:30:39:04' ),
        "created object with wwn"
    );
    isa_ok( $obj, 'Device::WWN::HP::XP' );
    is( $obj->normalized, '50060e8004303904', 'normalized value OK' );
    is( $obj->oui->oui, '0060E8', 'oui value OK' );
    is( $obj->oui->norm, '00-60-E8', 'oui normalized value OK' );
    is( $obj->naa, 5, 'naa value OK' );
    is( $obj->vendor_id, '004303904', 'vendor_id value OK' );
    is( $obj->serial_number, '12345', 'serial_number value OK' );
    is( $obj->family_id, '04', 'family_id value OK' );
    is( $obj->port, '1E', 'port value OK' );
    is( $obj->family, 'XP12000/XP10000', 'family value OK' );
}

{
    ok( my $obj = Device::WWN::HP::XP->new( {
        family_id       => '04',
        port            => '1E',
        serial_number   => '12345',
    } ), 'created object with values' );
    is( $obj->normalized, '50060e8004303904', 'normalized value OK' );
}

{
    ok( my $obj = Device::WWN::HP::XP->new( {
        family_id       => '04',
        port            => '1A',
        serial_number   => '43981',
    } ), 'created object with values' );
    is( $obj->normalized, '50060e8004abcd00', 'normalized value OK' );
}
