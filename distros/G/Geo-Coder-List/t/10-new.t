#!perl -wT

use strict;

use Scalar::Util qw(blessed);
use Test::Most tests => 13;

BEGIN {
	use_ok('Geo::Coder::List');
}

isa_ok(Geo::Coder::List->new(), 'Geo::Coder::List', 'Creating Geo::Coder::List object');
isa_ok(Geo::Coder::List::new(), 'Geo::Coder::List', 'Creating Geo::Coder::List object');
isa_ok(Geo::Coder::List->new()->new(), 'Geo::Coder::List', 'Cloning Geo::Coder::List object');
# ok(!defined(Geo::Coder::List::new()));

# Test 1: Basic object instantiation
my $object = Geo::Coder::List->new();
isa_ok($object, 'Geo::Coder::List', 'Object created with ->new() is of correct class');

# Test 2: Passing arguments as hash
my $object_with_args = Geo::Coder::List->new(debug => 1, geo_coders => ['Google']);
is($object_with_args->{debug}, 1, 'debug flag set correctly');
is_deeply($object_with_args->{geo_coders}, ['Google'], 'geo_coders set correctly from hash');

# Test 3: Passing arguments as hashref
my $args_ref = { debug => 1, geo_coders => ['Bing'] };
my $object_with_hashref_args = Geo::Coder::List->new($args_ref);
is($object_with_hashref_args->{debug}, 1, 'debug flag set correctly from hashref');
is_deeply($object_with_hashref_args->{geo_coders}, ['Bing'], 'geo_coders set correctly from hashref');

# Test 4: Cloning an object with new arguments
my $cloned_object = $object_with_args->new(debug => 0);
ok(blessed($cloned_object), 'Cloned object is blessed');
is($cloned_object->{debug}, 0, 'Cloned object has new debug value');
cmp_ok($cloned_object->{geo_coders}[0], 'eq', 'Google', 'Cloned object retains original geo_coders value');

# Test 5: Using ::new() syntax
eval {
	my $incorrect_object = Geo::Coder::List::new();
	isa_ok($incorrect_object, 'Geo::Coder::List', 'Object created with ::new() is of correct class');
};
