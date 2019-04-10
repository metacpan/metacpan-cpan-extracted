use strict;
use warnings;
use 5.010;

use Test::More tests => 5;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::SysInfo;

open(my $fh, '<:encoding(UTF8)', './t/xml/05-system_info.t.xml') or BAIL_OUT('Could not open XML file');

ok( $fh, 'XML file' ); 
my $xml = do { local $/ = undef, <$fh> };
ok( $xml, 'XML response' );

my $api = Device::Firewall::PaloAlto::API::_check_api_response($xml);

my $sysinfo = Device::Firewall::PaloAlto::Op::SysInfo->_new($api);

isa_ok( $sysinfo, 'Device::Firewall::PaloAlto::Op::SysInfo' );

is( $sysinfo->hostname, 'PA-VM', 'Hostname' );
is( $sysinfo->mgmt_ip, '192.168.122.20', 'MGMT IP' ); 
