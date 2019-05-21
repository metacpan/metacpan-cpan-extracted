
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

my @interfaces = $fw->op->interfaces->to_array;

my $interface_regex = qr{^(
    ethernet\d+/\d+(\.\d+)? |
    vlan(\.\d+)? |
    loopback(\.\d+)? |
    tunnel(\.\d+)? |
    ae\d+(\.\d+)? |
    ha(1|2)
$)}xms;

for my $interface (@interfaces) {
    my $name = $interface->name;
    # Does the interface name make sense
    ok( $name =~ $interface_regex, "($name) name" );

    my $int_obj = $fw->op->interfaces->interface( $name );
    isa_ok($int_obj, 'Device::Firewall::PaloAlto::Op::Interface', 'Interface Object' );
    cmp_ok( $int_obj->name, 'eq', $name, 'Interface name vs Index' );

    # Is the interface state either down or up
    ok( $interface->state =~ m{^down|up$}xms, "($name) state" );

    # IPv4 address should either be a proper IPv4 or an empty string
    like( $interface->ip, qr{\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\/\d{1,2}|^$}xms, "($name) IP Address" );

    like( $interface->vsys, qr{\d+}, "($name) vsys ID" );

}



## Test Module ##

my $test = $fw->test;

ok( $test->interfaces('ethernet1/1', 'loopback.1', 'vlan.32'), 'Test interfaces up' );
ok( !$test->interfaces('ethernet1/1', 'ethernet1/4', 'ethernet1/5'), 'Test up and down interfaces' );
ok( !$test->interfaces('ethernet1/4', 'ethernet1/7'), 'Test all down interfaces' );
ok( !$test->interfaces('ethernet1/1', 'ethernet2/2'), 'Test missing interfaces' );

done_testing();
