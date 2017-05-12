#!perl
use strict; use warnings;
use Test::Most tests => 23;
use ok 'Device::MAC';

my @values = (
    {
        mac             => '00:19:e3:01:0e:72',
        normalized      => '00:19:e3:01:0e:72',
        oui             => '0019e3',
        oui_norm        => '00-19-E3',
        is_universal    => 1,
        is_local        => 0,
        is_unicast      => 1,
        is_multicast    => 0,
    },
    {
        mac             => '00:1c:42:00:00:00',
        normalized      => '00:1c:42:00:00:00',
        oui             => '001c42',
        oui_norm        => '00-1C-42',
        is_universal    => 1,
        is_local        => 0,
        is_unicast      => 1,
        is_multicast    => 0,
    },
);

for my $x ( @values ) {
    explain "About to test ", $x;
    ok(
        my $mac = Device::MAC->new( $x->{ 'mac' } ),
        "Created an object for $x->{ 'mac' }"
    );
    isa_ok( $mac, 'Device::MAC' );

    is( $mac->mac, delete $x->{ 'mac' }, 'MAC value OK' );
    is( $mac->normalized, delete $x->{ 'normalized' }, 'normalized value OK' );

    ok( my $oui = $mac->oui, "Got a value from OUI" );
    is( $oui->oui, delete $x->{ 'oui' }, 'OUI value OK' );
    is( $oui->norm, delete $x->{ 'oui_norm' }, 'OUI normalized value OK' );
    for my $key ( keys %{ $x } ) {
        is( $mac->$key, $x->{ $key }, "$key value OK" );
    }
}
