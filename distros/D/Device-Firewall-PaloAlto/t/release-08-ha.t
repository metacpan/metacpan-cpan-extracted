
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


my $a = $fw->op->ha;
isa_ok($a, 'Device::Firewall::PaloAlto::Op::HA');

like( $a->enabled, qr(1|^$), 'Enabled' );

my ($l_state, $r_state) = $a->state;
like( $l_state, qr(active|passive|unknown), 'Local State' );
like( $r_state, qr(^(active|passive|unknown)$), 'Remote State' );

like( $a->connection_status, qr(1|^$), 'Connection Status' );

my %compat = $a->compatibility;

if ($a->enabled) {
    for my $key (qw(app av build gpclient threat url vpnclient)) {
        like( $compat{$key}, qr(^(Unknown)$), "Compatibility: $key" );
    }
} else {
    ok(!$a->compatibility, 'Compatibility with non-enabled HA' );
}

done_testing();
    
