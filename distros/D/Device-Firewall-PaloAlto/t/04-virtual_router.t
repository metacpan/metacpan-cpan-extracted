use strict;
use warnings;
use 5.010;

use Test::More tests => 19;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::VirtualRouter;

open(my $fh, '<:encoding(UTF8)', './t/xml/04-virtual_router.t.xml') or BAIL_OUT('Could not open XML file');

ok( $fh, 'XML file' ); 
my $xml = do { local $/ = undef, <$fh> };
ok( $xml, 'XML response' );

my $api = Device::Firewall::PaloAlto::API::_check_api_response($xml);

my $vr = Device::Firewall::PaloAlto::Op::VirtualRouter->_new($api);

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

is( scalar @next_hops, 2, 'Next hops' );

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

