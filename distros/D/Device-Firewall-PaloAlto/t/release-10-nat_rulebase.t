
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



my $test_obj = $fw->test;
isa_ok($test_obj, 'Device::Firewall::PaloAlto::Test');

my @nat_calls = (
    { 
        args => { from => 'TRUST', to => 'UNTRUST', src_ip => q(192.168.130.3), dst_ip => q(192.168.130.2), dst_port => 84 },
        name => 'Destination Dynamic with Port Translation' 
    },
    { 
        args => { from => 'TRUST', to => 'UNTRUST', src_ip => q(192.168.130.3), dst_ip => q(192.168.130.1), dst_port => 83 }, 
        name => 'Destination Static with Port Translation' 
    },
    { 
        args => { from => 'TRUST', to => 'UNTRUST', src_ip => q(192.168.130.3), dst_ip => q(192.168.130.1), dst_port => 80 }, 
        name => 'Source Dynamic IP and Port Interface' 
    },
    { 
        args => { from => 'TRUST', to => 'UNTRUST', src_ip => q(192.168.130.3), dst_ip => q(192.168.130.1), dst_port => 81 }, 
        name => 'Source Dynamic IP' 
    },
    { 
        args => { from => 'TRUST', to => 'UNTRUST', src_ip => q(192.168.130.3), dst_ip => q(192.168.130.1), dst_port => 82 }, 
        name => 'Source Static Bi-directional' 
    },
);

for my $test (@nat_calls) {
    my $a = $test_obj->nat_policy( %{ $test->{args} } );
    isa_ok( $a, 'Device::Firewall::PaloAlto::Test::NATPolicy' );

    is( $a->rulename, $test->{name}, 'Rulename matches' );
    ok( $a, 'Correct bool overload' );
}


done_testing();
