use strict;
use warnings;
use 5.010;

use Test::More tests => 11;
use Device::Firewall::PaloAlto::API;
use Device::Firewall::PaloAlto::Op::GlobalCounters;

open(my $fh, '<:encoding(UTF8)', './t/xml/07-global_counters.t.xml') or BAIL_OUT('Could not open XML file');

ok( $fh, 'XML file' ); 
my $xml = do { local $/ = undef, <$fh> };
ok( $xml, 'XML response' );

my $api = Device::Firewall::PaloAlto::API::_check_api_response($xml);

my $cntrs = Device::Firewall::PaloAlto::Op::GlobalCounters->_new($api);

isa_ok( $cntrs, 'Device::Firewall::PaloAlto::Op::GlobalCounters' );

my @counters = $cntrs->to_array;
is( scalar @counters, 46, 'Number of counters' );

my $c = $cntrs->name('flow_policy_nofwd');
ok( $c, 'Existent Counter' );
isa_ok( $c, 'Device::Firewall::PaloAlto::Op::GlobalCounter', 'Global Counter' );
ok(! $cntrs->name('invalid name'), 'Non-existent counter' );

is( $c->name, 'flow_policy_nofwd', 'Counter name' );
is( $c->rate, 0, 'Counter rate' );
is( $c->value, 29, 'Counter value' );
is( $c->severity, 'drop', 'Counter severity' );




