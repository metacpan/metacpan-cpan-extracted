use strict;
use warnings;
use 5.010;

use Test::More tests => 18;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Test::NATPolicy;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);


#### If the flow doesn't hit any NAT policy
my $nonat = pseudo_api_call(
    "t/xml/test/natpolicy/8.1.3/no_nat_hit.xml", 
    sub { Device::Firewall::PaloAlto::Test::NATPolicy->_new(@_) }
);
isa_ok( $nonat, 'Device::Firewall::PaloAlto::Test::NATPolicy' );

ok( !$nonat, 'No NAT Policy Bool Overload' );
is( $nonat->rulename, '', 'No NAT Policy Rulename' );


#### 8.1.3 Tests - due to a bug, this Palo Alto version only returns the 
# name of the NAT rule
my @api_xml_info = (
    { file => 'dst_dyn_port_trans.xml', name => 'Destination Dynamic with Port Translation' },
    { file => 'dst_static_port_trans.xml', name => 'Destination Static with Port Translation' },
    { file => 'source_dynamic_ip_port.xml', name => 'Source Dynamic IP and Port Interface' },
    { file => 'source_dynamic_ip.xml', name => 'Source Dynamic IP' },
    { file => 'source_static_bidir.xml', name => 'Source Static Bi-directional' },
);


for my $nat_rule (@api_xml_info) {
    my $r = pseudo_api_call(
        "t/xml/test/natpolicy/8.1.3/$nat_rule->{file}", 
        sub { Device::Firewall::PaloAlto::Test::NATPolicy->_new(@_) }
    );

    isa_ok( $r, 'Device::Firewall::PaloAlto::Test::NATPolicy' );

    ok( $r, 'NAT Bool Overload' );
    is( $r->rulename, $nat_rule->{name}, "NAT Rule Name Match" );
}
