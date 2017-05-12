#!perl
use strict; use warnings;
use Test::Most tests => 213;
use ok 'Device::WWN';

my @values = (
    {
        wwn             => '10:00:00:00:c9:22:fc:01',
        normalized      => '10000000c922fc01',
        oui             => '0000c9',
        oui_norm        => '00-00-C9',
        #class           => '',
        #serial_number   => '',
        #port            => '',
        naa             => '1',
        vendor_id       => '22fc01',
    },
    {
        wwn             => '200000e069415402',
        normalized      => '200000e069415402',
        oui             => '00e069',
        oui_norm        => '00-E0-69',
        #class           => '',
        #serial_number   => '',
        #port            => '',
        naa             => '2',
        vendor_code     => '000',
        vendor_id       => '415402',
    },
    {
        wwn             => '20:00:00:e0:69:41:54:02',
        normalized      => '200000e069415402',
        oui             => '00e069',
        oui_norm        => '00-E0-69',
        #class           => '',
        #serial_number   => '',
        #port            => '',
        naa             => '2',
        vendor_code     => '000',
        vendor_id       => '415402',
    },
    {
        wwn             => '2000:00e0:6941:5402',
        normalized      => '200000e069415402',
        oui             => '00e069',
        oui_norm        => '00-E0-69',
        #class           => '',
        #serial_number   => '',
        #port            => '',
        naa             => '2',
        vendor_code     => '000',
        vendor_id       => '415402',
    },
    {
        wwn             => '50:06:04:81:D6:F3:45:42',
        normalized      => '50060481d6f34542',
        oui             => '006048',
        oui_norm        => '00-60-48',
        class           => 'Device::WWN::EMC::Symmetrix',
        serial_number   => '123456789',
        port            => '03AA',
        naa             => '5',
        vendor_id       => '1d6f34542',
    },
    {
        wwn             => '200000e069415402',
        normalized      => '200000e069415402',
        oui             => '00e069',
        oui_norm        => '00-E0-69',
        naa             => '2',
        vendor_code     => '000',
        vendor_id       => '415402',
    },
    {
        wwn             => '200000e0694157a0',
        normalized      => '200000e0694157a0', 
        oui             => '00e069',
        oui_norm        => '00-E0-69',
        naa             => '2',
        vendor_code     => '000',
        vendor_id       => '4157a0', 
    },
    {
        wwn             => '200000e069415773',
        normalized      => '200000e069415773',
        oui             => '00e069',
        oui_norm        => '00-E0-69',
        naa             => '2',
        vendor_code     => '000',
        vendor_id       => '415773',
    },
    {
        wwn             => '200000e069415036',
        normalized      => '200000e069415036',
        oui             => '00e069',
        oui_norm        => '00-E0-69',
        naa             => '2',
        vendor_code     => '000',
        vendor_id       => '415036',
    },
    {
        wwn             => '10000000c9282238',
        normalized      => '10000000c9282238',
        oui             => '0000c9',
        oui_norm        => '00-00-C9',
        naa             => '1',
        vendor_id       => '282238',
    },
    {
        wwn             => '10000000c9282256',
        normalized      => '10000000c9282256',
        oui             => '0000c9',
        oui_norm        => '00-00-C9',
        naa             => '1',
        vendor_id       => '282256',
    },
    {
        wwn             => '500604872363ee43',
        normalized      => '500604872363ee43',
        oui             => '006048',
        oui_norm        => '00-60-48',
        class           => 'Device::WWN::EMC::Symmetrix',
        serial_number   => '479039417',
        port            => '04AA',
        naa             => '5',
        vendor_id       => '72363ee43',
    },
    {
        wwn             => '500604872363ee53',
        normalized      => '500604872363ee53',
        oui             => '006048',
        oui_norm        => '00-60-48',
        class           => 'Device::WWN::EMC::Symmetrix',
        serial_number   => '479039417',
        port            => '04BA',
        naa             => '5',
        vendor_id       => '72363ee53',
    },
    {
        wwn             => '500604872363ee4c',
        normalized      => '500604872363ee4c', 
        oui             => '006048',
        oui_norm        => '00-60-48',
        class           => 'Device::WWN::EMC::Symmetrix',
        serial_number   => '479039417',
        port            => '13AA',
        naa             => '5',
        vendor_id       => '72363ee4c', 
    },
    {
        wwn             => '500604872363ee5c',
        normalized      => '500604872363ee5c',
        oui             => '006048',
        oui_norm        => '00-60-48',
        class           => 'Device::WWN::EMC::Symmetrix',
        serial_number   => '479039417',
        port            => '13BA',
        naa             => '5',
        vendor_id       => '72363ee5c',
    },
    {
        wwn             => '5006016012345678',
        normalized      => '5006016012345678',
        oui             => '006016',
        oui_norm        => '00-60-16',
        class           => 'Device::WWN::EMC::Clariion',
        port            => 'SPA0',
        naa             => '5',
        vendor_id       => '012345678',
    },
    {
        wwn             => '50:6:e:80:4:ab:cd:0',
        normalized      => '50060e8004abcd00',
        oui             => '0060E8',
        oui_norm        => '00-60-E8',
        class           => 'Device::WWN::HP::XP',
        naa             => '5',
        vendor_id       => '004abcd00',
        serial_number   => '43981',
        family_id       => '04',
        port            => '1A',
        family          => 'XP12000/XP10000',
    },
    {
        wwn             => '50:06:0e:80:04:30:39:04',
        normalized      => '50060e8004303904',
        oui             => '0060E8',
        oui_norm        => '00-60-E8',
        class           => 'Device::WWN::HP::XP',
        naa             => '5',
        vendor_id       => '004303904',
        serial_number   => '12345',
        family_id       => '04',
        port            => '1E',
        family          => 'XP12000/XP10000',
    },
);

for my $x ( @values ) {
    #explain "About to test ", $x;
    my $class = delete $x->{ 'class' } || 'Device::WWN';
    Class::MOP::load_class( $class );
    unless ( $class eq 'Device::WWN' ) {
        my @sc = grep { $_ eq $class }
            Device::WWN->find_subclasses( $x->{ 'wwn' } );
        ok( @sc == 1, "find_subclasses finds one class for $x->{ 'wwn' }" );
        is( $sc[0], $class, "find_subclasses found $class for $x->{ 'wwn' }" );
        ok( @sc > 0, "find_subclasses finds $class for $x->{ 'wwn' }" );
    }
    ok(
        my $wwn = $class->new( $x->{ 'wwn' } ),
        "Created a $class object for $x->{ 'wwn' }"
    );
    isa_ok( $wwn, 'Device::WWN' );

    is( $wwn->wwn, delete $x->{ 'wwn' }, 'WWN value OK' );
    is( $wwn->normalized, delete $x->{ 'normalized' }, 'normalized value OK' );

    ok( my $oui = $wwn->oui, "Got a value from OUI" );
    is( $oui->oui, delete $x->{ 'oui' }, 'OUI value OK' );
    is( $oui->norm, delete $x->{ 'oui_norm' }, 'OUI normalized value OK' );
    for my $key ( keys %{ $x } ) {
        is( $wwn->$key, $x->{ $key }, "$key value OK" );
    }

    if ( $x->{ 'class' } ) {
        ok(
            my $obj = Device::WWN->new( $x->{ 'wwn' } ),
            "Created a Device::WWN object with $x->{ 'wwn' }",
        );
        isa_ok( $obj, $x->{ 'class' }, "It was reblessed correctly" );
    }
}
