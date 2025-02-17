#!perl -w

use strict;

# use lib 'lib';
use Test::Most tests => 7;

BEGIN { use_ok('HTML::OSM') }

isa_ok(HTML::OSM->new(), 'HTML::OSM', 'Creating HTML::OSM object');
isa_ok(HTML::OSM::new(), 'HTML::OSM', 'Creating HTML::OSM object');
isa_ok(HTML::OSM->new()->new(), 'HTML::OSM', 'Cloning HTML::OSM object');
# ok(!defined(HTML::OSM::new()));

# Create a new object with direct key-value pairs
my $obj = HTML::OSM->new(zoom => 10, coordinates => [ 1, 2 ]);
cmp_ok($obj->{'zoom'}, '==', 10, 'direct key-value pairs');

# Test cloning behaviour by calling new() on an existing object
my $obj2 = $obj->new({ cooordinates => [ 3, 4 ] });
cmp_ok($obj2->{zoom}, '==', 10, 'clone keeps old args');
cmp_ok($obj2->{cooordinates}[0], '==', 3, 'clone adds new args');
