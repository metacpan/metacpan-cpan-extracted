use strict;
use warnings;
use 5.010;

use Test::More tests => 3;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::SysInfo;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);

my $sysinfo = pseudo_api_call(
    './t/xml/op/system_info/system_info.xml', 
    sub { Device::Firewall::PaloAlto::Op::SysInfo->_new(@_) }
);

isa_ok( $sysinfo, 'Device::Firewall::PaloAlto::Op::SysInfo' );

is( $sysinfo->hostname, 'PA-VM', 'Hostname' );
is( $sysinfo->mgmt_ip, '192.168.122.20', 'MGMT IP' ); 
