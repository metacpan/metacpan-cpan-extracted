
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use Test::More;
use Device::Firewall::PaloAlto;
use Regexp::Common qw(net);

my $fw = Device::Firewall::PaloAlto->new(verify_hostname => 0)->auth;
ok($fw, "Firewall Object") or BAIL_OUT("Unable to connect to FW object: @{[$fw->error]}");


my $sys_info = $fw->op->system_info;
isa_ok($sys_info, 'Device::Firewall::PaloAlto::Op::SysInfo');

ok( $sys_info, "System Info" );
ok( $sys_info->hostname, "System hostname" );
like( $sys_info->mgmt_ip, qr($RE{net}{IPv4}), "MGMT IP" );


done_testing();
