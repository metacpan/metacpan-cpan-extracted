
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More tests => 3;
use Device::Firewall::PaloAlto;

my $fw = Device::Firewall::PaloAlto->new(verify_hostname => 0)->auth;
ok($fw, "Firewall Object") or BAIL_OUT("Unable to connect to FW object: @{[$fw->error]}");


my $log_status = $fw->op->logging_status();
ok( $log_status, 'Log status object defined' );
isa_ok( $log_status, 'Device::Firewall::PaloAlto::Op::LogStatus', 'Log status object returned' );
