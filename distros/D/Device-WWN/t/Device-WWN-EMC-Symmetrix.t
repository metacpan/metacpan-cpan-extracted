#!perl
use strict; use warnings;
use Test::Most tests => 6;
use ok 'Device::WWN::EMC::Symmetrix';
use ok 'Device::WWN';

ok( my $obj = Device::WWN::EMC::Symmetrix->new( {
    serial_number       => '123456789',
    port                => '03AA',
} ), "created object with serial/port" );
is( $obj->wwn, '50060481d6f34542', "wwn OK" );

ok( my $obj2 = Device::WWN->new( {
    wwn => '50060481d6f34542',
} ), 'created new Device::WWN object for 50060481d6f34542' );
isa_ok( $obj2, 'Device::WWN::EMC::Symmetrix' );

__END__
my @values = (
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
        wwn             => '500604872363ee43',
        normalized      => '500604872363ee43',
        oui             => '006048',
        oui_norm        => '00-60-48',
        class           => 'Device::WWN::EMC::Symmetrix',
        serial_number   => '479039417',
        port            => '04AA', # fa4a
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
        port            => '04BA', # fa4b
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
        port            => '13AA', # fa13a
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
        port            => '13BA', # fa13b
        naa             => '5',
        vendor_id       => '72363ee5c',
    },
);

for my $x ( @values ) {
    #explain "About to test ", $x;
    my $class = delete $x->{ 'class' } || 'Device::WWN';
    Class::MOP::load_class( $class );
    unless ( $class eq 'Device::WWN' ) {
        my @sc = grep { $_ eq $class }
            Device::WWN->find_subclasses( $x->{ 'wwn' } );
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
}
