
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

# User-ID mappings, some with timeouts
my @mappings = (
    ['192.0.2.1', 'test_user_a'],
    ['192.0.2.2', 'domain_a\test_user_b'],
    ['192.0.2.3', 'domain_b\test_user_c', 200],
    ['192.0.2.4', 'test_user_d', 4000]
);


# Check the mappings
for my $m (@mappings) {
    # Add the mapping
    ok( $fw->user_id->add_ip_mapping(@{$m}), "User mapping added (IP $m->[0])" );

    # Check the mapping  
    my $mapping = $fw->op->ip_user_mapping->ip($m->[0]);
    isa_ok($mapping, 'Device::Firewall::PaloAlto::Op::IPUserMap');

    # Can we output JSON?
    can_ok($mapping, 'to_json');

    # Are the values correct?
    ok( $mapping, "IP user mapping" );
    is( $mapping->ip, $m->[0], 'IP matches' );
    is( $mapping->user, $m->[1], 'User matches' );

    # Remove the mapping
    ok( $fw->user_id->rm_ip_mapping(@{$m}), "User mapping removed (IP $m->[0])" );

    # Confirm the mapping isn't there
    ok( !$fw->op->ip_user_mapping->ip($m->[0]), "Mapping removed (IP $m->[0])" );
}

# Reach out and get all the mappings.
my $ip_mappings = $fw->op->ip_user_mapping();
isa_ok($ip_mappings, 'Device::Firewall::PaloAlto::Op::IPUserMaps');
can_ok($ip_mappings, 'to_json');





done_testing();
