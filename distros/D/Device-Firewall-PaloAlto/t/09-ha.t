use strict;
use warnings;
use 5.010;

use Test::More tests => 16;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::HA;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);


### HA Enabled Tests ### 
my $a = pseudo_api_call(
    './t/xml/op/ha/ha_enabled.xml', 
    sub { Device::Firewall::PaloAlto::Op::HA->_new(@_) }
);

isa_ok( $a, 'Device::Firewall::PaloAlto::Op::HA' );

my $b = $a->enabled;

ok( $a->enabled, 'HA Enabled' );

my @states = $a->state;
is( $states[0], 'active', 'Local state' );
is( $states[1], 'unknown', 'Remote state' );

ok( !$a->connection_status, 'HA connection state' );

my %compat = $a->compatibility;
is( $_, 'Unknown', 'HA Compatibility' ) foreach values %compat;



### HA Disabled Tests ### 
$a = pseudo_api_call(
    './t/xml/op/ha/ha_disabled.xml', 
    sub { Device::Firewall::PaloAlto::Op::HA->_new(@_) }
);

isa_ok( $a, 'Device::Firewall::PaloAlto::Op::HA' );

ok( !$a->enabled, 'HA Disabled' );
ok( !$_, 'Disabled HA State' ) foreach $a->state;
ok( !$a->connection_status, 'HA connection state' );
%compat = $a->compatibility;
ok( !%compat, 'Disabled HA Compatibility' ); 


