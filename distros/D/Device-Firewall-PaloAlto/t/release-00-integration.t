
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More;

use Device::Firewall::PaloAlto;

my $fw = Device::Firewall::PaloAlto->new(uri => 'http://pa.localdomain', username => 'admin', password => 'admin');

isa_ok( $fw, 'Device::Firewall::PaloAlto', 'Device::Firewall::PaloAlto Object' ) or BAIL_OUT('Object Initialisation');

done_testing();
