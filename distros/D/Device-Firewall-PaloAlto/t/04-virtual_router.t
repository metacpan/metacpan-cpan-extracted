use strict;
use warnings;
use 5.010;

use Test::More tests => 20;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::VirtualRouter;

use lib 't/lib';
use Local::TestSupport qw(pseudo_api_call);

### Virtual router with routes present ###
my $vr = pseudo_api_call(
    './t/xml/op/virtual_router/vr_with_routes.xml', 
    sub { Device::Firewall::PaloAlto::Op::VirtualRouter->_new(@_) }
);
isa_ok( $vr, 'Device::Firewall::PaloAlto::Op::VirtualRouter' );

my $route = $vr->route('0.0.0.0/0');
ok( $route, 'Route entry' );
isa_ok( $route, 'Device::Firewall::PaloAlto::Op::Route' );
ok(! $vr->route('100.100.100.100/32'), 'Non-existent route' );

my @routes = $vr->to_array;
is( scalar @routes, 16, 'Number active routes of routes in array' );

# Both the virtual routes and the route support the to_json method
ok( $vr->can('to_json'), 'Virtual router to_json' );
ok( $route->can('to_json'), 'Route to_json' );

# Check the values of the route
is( $route->destination, '0.0.0.0/0', 'Route destination' );
my @next_hops = $route->next_hops;

is( @next_hops, 2, 'Next hops' );

for my $nh (@next_hops) {
    cmp_ok(ref $nh, 'eq', 'HASH', 'Next hop hash');
    # All the keys are in place
    is( scalar keys %{$nh}, 5, 'Next hop keys' );
}

is( $route->protocol, 'static', 'Route protocol' );

ok( $route->active, 'Route active' );
ok( $route->ecmp, 'Route is ECMP' );

# Check a non-ECMP route
ok(! $vr->route('1.1.5.3/32')->ecmp, 'Non-ECMP route' );

### Virtual router with no routes present ###
$vr = pseudo_api_call(
    './t/xml/op/virtual_router/vr_no_routes.xml',
    sub { Device::Firewall::PaloAlto::Op::VirtualRouter->_new(@_) }
);
isa_ok( $vr, 'Device::Firewall::PaloAlto::Op::VirtualRouter' );
ok(! $vr->route('0.0.0.0/0'), 'No route present' );

@routes = $vr->to_array();
is( @routes, 0, 'No route array has length 0' ); 

