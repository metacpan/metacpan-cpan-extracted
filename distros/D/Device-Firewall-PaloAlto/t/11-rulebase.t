use strict;
use warnings;
use 5.010;

use Test::More tests => 15;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Test::Rulebase;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);


# Testing a Rulebase call where a flow was
# permitted
my $r = pseudo_api_call(
    't/xml/test/rulebase/flow_permit.xml', 
    sub { Device::Firewall::PaloAlto::Test::Rulebase->_new(@_) }
);
isa_ok( $r, 'Device::Firewall::PaloAlto::Test::Rulebase' );

ok( $r, 'Permitted flow is true' );
is( $r->rulename, 'Tunnel Policy', 'Permit flow rulename' );
is( $r->action, 'allow', 'Permit flow action' );
is( $r->index, 4, 'Permit flow index' );



# Testing a Rulebase call where a flow was
# DENIED
$r = pseudo_api_call(
    't/xml/test/rulebase/flow_deny.xml', 
    sub { Device::Firewall::PaloAlto::Test::Rulebase->_new(@_) }
);
isa_ok( $r, 'Device::Firewall::PaloAlto::Test::Rulebase' );

ok( !$r, 'Denied flow is false' );
is( $r->rulename, 'Deny Policy', 'Deny flow rulename' );
is( $r->action, 'deny', 'Deny flow action' );
is( $r->index, 2, 'Deny flow index' );

# Testing a Rulebase call where a flow hit the default deny 
# rule
$r = pseudo_api_call(
    't/xml/test/rulebase/flow_default_deny.xml', 
    sub { Device::Firewall::PaloAlto::Test::Rulebase->_new(@_) }
);
isa_ok( $r, 'Device::Firewall::PaloAlto::Test::Rulebase' );

ok( !$r, 'Default deny rule is false' );
is( $r->rulename, '__DEFAULT_DENY__', 'Defauly deny rulename' );
is( $r->action, 'deny', 'Default deny action' );
is( $r->index, -1, 'Default deny flow index' );
