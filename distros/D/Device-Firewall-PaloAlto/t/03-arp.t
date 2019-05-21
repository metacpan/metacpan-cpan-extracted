use strict;
use warnings;
use 5.010;

use Test::More tests => 12;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::ARPTable;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);

my ($fh, $xml);

## ARP table with entries ###
my $arp_tbl = pseudo_api_call(
    './t/xml/op/arp/arp_entries.xml',
    sub { Device::Firewall::PaloAlto::Op::ARPTable->_new(@_) }
);
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



### ARP table with no entries ### 
$arp_tbl = pseudo_api_call(
    './t/xml/op/arp/arp_no_entries.xml',
    sub { Device::Firewall::PaloAlto::Op::ARPTable->_new(@_) }
);
isa_ok( $arp_tbl, 'Device::Firewall::PaloAlto::Op::ARPTable' );

is( $arp_tbl->current_entries, 0, 'Current Entries no ARP' );
is( $arp_tbl->max_entries, 250, 'Max Entries' );

$arp = $arp_tbl->entry('192.168.122.1');
ok( !$arp, 'No ARP entry' );

