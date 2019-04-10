use strict;
use warnings;
use 5.010;

use Test::More tests => 10;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::IPUserMaps;

open(my $fh, '<:encoding(UTF8)', './t/xml/08-user_id.t.xml') or BAIL_OUT('Could not open XML file');

ok( $fh, 'XML file' ); 
my $xml = do { local $/ = undef, <$fh> };
ok( $xml, 'XML response' );

my $api = Device::Firewall::PaloAlto::API::_check_api_response($xml);

my $map = Device::Firewall::PaloAlto::Op::IPUserMaps->_new($api);

isa_ok( $map, 'Device::Firewall::PaloAlto::Op::IPUserMaps' );

my @mappings = $map->to_array;
is( scalar @mappings, 5, 'Number of counters' );

# Get a valid IP mapping
my $ipusrmap = $map->ip('192.0.2.1');
ok( $ipusrmap, 'IP user mapping' );
isa_ok( $ipusrmap, 'Device::Firewall::PaloAlto::Op::IPUserMap' );

# Check the values
is( $ipusrmap->ip, '192.0.2.1', 'IP mapping IP' );
is( $ipusrmap->user, 'localdomainser_a', 'IP mapping user' );
is( $ipusrmap->type, 'XMLAPI', 'IP mapping type' );
is( $ipusrmap->vsys, 'vsys1', 'IP mapping vsys' );




