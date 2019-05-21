use strict;
use warnings;
use 5.010;

use Test::More tests => 7;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::Interfaces;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);


my $interfaces = pseudo_api_call(
    './t/xml/op/interfaces/interfaces.xml', 
    sub { Device::Firewall::PaloAlto::Op::Interfaces->_new(@_) }
);

isa_ok( $interfaces, 'Device::Firewall::PaloAlto::Op::Interfaces' );

my $interface = $interfaces->interface('ethernet1/1');
isa_ok( $interface, 'Device::Firewall::PaloAlto::Op::Interface' );
is( $interface->name, 'ethernet1/1', 'Interface Name' );
is( $interface->state, 'up', 'Interface State' );
is( $interface->vsys, '1', 'Interface VSys' );

$interfaces = pseudo_api_call(
    './t/xml/op/interfaces/no_interfaces.xml', 
    sub { Device::Firewall::PaloAlto::Op::Interfaces->_new(@_) }
);
isa_ok( $interfaces, 'Device::Firewall::PaloAlto::Op::Interfaces' );

is( $interfaces->to_array, 0, 'No interfaces array' );




