
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

my @rulebase_tests = (
    {
        args => { from => 'TRUST', to => 'UNTRUST', src_ip => q(1.1.1.1), dst_ip => q(2.2.2.2), dst_port => 443 },
        allow => 0,
        rulename => 'Deny Policy',
        index => qr(\d+),
    },
    {
        args => { from => 'TUNNEL', to => 'TUNNEL', src_ip => q(1.1.1.1), dst_ip => q(2.2.2.2) },
        allow => 1,
        rulename => 'Tunnel Policy',
        index => qr(\d+),
    },
    {
        args => { from => 'TRUST', to => 'UNTRUST', src_ip => q(1.1.1.1), dst_ip => q(2.2.2.2), dst_port => 22 },
        allow => 0,
        rulename => '__DEFAULT_DENY__',
        index => qr(\d+),
    },
);

for my $test (@rulebase_tests) {
    my $a = $test_obj->sec_policy( %{ $test->{args} } );
    isa_ok( $a, 'Device::Firewall::PaloAlto::Test::SecPolicy' );

    is( $a->rulename, $test->{rulename}, 'Rulename matches' );
    like( $a->index, $test->{index}, 'Index matches' );

    $test->{allow} ?
        ok( $a, 'Object has correct boolean overload (true)' )
    :   ok( !$a, 'Object has correct boolean overload (false)' );
    
}

# Try some tests with string protocols

ok( $test_obj->sec_policy( 
        from => 'TUNNEL', 
        to => 'TUNNEL', 
        src_ip => q(1.1.1.1), 
        dst_ip => q(2.2.2.2), 
        protocol => 'tcp' 
    ), 'Policy test with a string protocol' );


done_testing();
