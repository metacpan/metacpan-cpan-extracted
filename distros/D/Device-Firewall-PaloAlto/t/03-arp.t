use strict;
use warnings;
use 5.010;

use Test::More tests => 10;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::ARPTable;

open(my $fh, '<:encoding(UTF8)', './t/xml/03-arp.t.xml') or BAIL_OUT('Could not open XML file');
ok( $fh, 'XML file' ); 

my $xml = do { local $/ = undef, <$fh> };

ok( $xml, 'XML response' );

my $api = Device::Firewall::PaloAlto::API::_check_api_response($xml);

my $arp_tbl = Device::Firewall::PaloAlto::Op::ARPTable->_new($api);

isa_ok( $arp_tbl, 'Device::Firewall::PaloAlto::Op::ARPTable' );

is( $arp_tbl->current_entries, 4, 'Current Entries' );
is( $arp_tbl->max_entries, 250, 'Max Entries' );

my $arp = $arp_tbl->entry('192.168.122.1');
ok( $arp, 'ARP entry' );
isa_ok( $arp, 'Device::Firewall::PaloAlto::Op::ARPEntry' );
is( $arp->mac, '52:54:00:d8:ec:73', 'ARP MAC' );
is( $arp->status, 'complete', 'ARP Status' );

# Invalid entry returns false
ok( !$arp_tbl->entry('1.1.1.1'), 'Invalid Entry' );






