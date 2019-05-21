
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More;
use Device::Firewall::PaloAlto;

my $fw = Device::Firewall::PaloAlto->new(verify_hostname => 0)->auth;
ok($fw, "Firewall Object") or BAIL_OUT("Unable to connect to FW object: @{[$fw->error]}");


my $arp_table = $fw->op->arp_table;
isa_ok($arp_table, 'Device::Firewall::PaloAlto::Op::ARPTable');

ok( $arp_table, "ARP Table" );
like( $arp_table->current_entries, qr(\d+), "ARP Entries" );
like( $arp_table->max_entries, qr(\d+), "ARP Entries" );

my @arp_entries = $arp_table->to_array();

for my $arp_entry (@arp_entries) {
    isa_ok( $arp_entry, 'Device::Firewall::PaloAlto::Op::ARPEntry', 'ARP Entry object' );

    # Check the MAC address
    like( $arp_entry->mac, qr{ ([0-9a-f]{2}) (:[0-9a-f]{2}){5} }xms, 'MAC Address' );
    like( $arp_entry->status, qr{static|complete|expiring|incomplete}, "MAC Status" );
}
    

### Test Module ###

my $test = $fw->test;
isa_ok($test, 'Device::Firewall::PaloAlto::Test');

ok( $test->arp('10.101.10.11', '10.101.10.11'), 'Valid entries' );
ok( !$test->arp('192.0.2.1', '192.0.2.2'), 'Invalid entries' );
ok( !$test->arp('10.101.10.11', '192.0.2.1'), 'Valid and invalud entries' );
ok( $test->arp(), 'No entries' );

done_testing();
