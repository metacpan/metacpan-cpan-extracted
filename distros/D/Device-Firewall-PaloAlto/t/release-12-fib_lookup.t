
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More tests => 6;
use Device::Firewall::PaloAlto;

my $fw = Device::Firewall::PaloAlto->new(verify_hostname => 0)->auth;
ok($fw, "Firewall Object") or BAIL_OUT("Unable to connect to FW object: @{[$fw->error]}");


my $fib = $fw->test->fib_lookup(ip => '1.1.1.1');
ok( $fib, 'FIB object defined' );
isa_ok($fib, 'Device::Firewall::PaloAlto::Test::FIB', 'FIB object returned' );

ok( $fib->is_ecmp, 'ECMP route' );
is( ($fib->interfaces)[0], 'ethernet1/1', 'FIB entry interface' );
is( ($fib->next_hops)[0], '192.168.122.2', 'FIB entry IP' );
