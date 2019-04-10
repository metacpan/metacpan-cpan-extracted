use strict;
use warnings;
use 5.010;

use Test::More tests => 7;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::Interfaces;

open(my $fh, '<:encoding(UTF8)', './t/xml/02-interfaces.t.xml') or BAIL_OUT('Could not open XML file');
ok( $fh, 'XML file' ); 

my $xml = do { local $/ = undef, <$fh> };

ok( $xml, 'XML response' );

my $api = Device::Firewall::PaloAlto::API::_check_api_response($xml);

my $interfaces = Device::Firewall::PaloAlto::Op::Interfaces->_new($api);

isa_ok( $interfaces, 'Device::Firewall::PaloAlto::Op::Interfaces' );

my $interface = $interfaces->interface('ethernet1/1');
isa_ok( $interface, 'Device::Firewall::PaloAlto::Op::Interface' );
is( $interface->name, 'ethernet1/1', 'Interface Name' );
is( $interface->state, 'up', 'Interface State' );
is( $interface->vsys, '1', 'Interface VSys' );






