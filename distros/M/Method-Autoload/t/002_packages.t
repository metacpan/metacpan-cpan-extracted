# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 17;

BEGIN { use_ok( 'Method::Autoload' ); }

my $object=Method::Autoload->new(packages=>[qw{One Two}]);
isa_ok ($object, 'Method::Autoload');
isa_ok (scalar($object->packages), 'ARRAY');

is(scalar(@{$object->packages}), 2, 'packages 1');
is($object->packages->[0], "One", 'packages 2');
is($object->packages->[1], "Two", 'packages 3');

$object->pushPackages("Three", "Four");

is(scalar(@{$object->packages}), 4, 'packages 4');
is($object->packages->[0], "One", 'packages 5');
is($object->packages->[1], "Two", 'packages 6');
is($object->packages->[2], "Three", 'packages 7');
is($object->packages->[3], "Four", 'packages 8');

$object->unshiftPackages("Zero");

is(scalar(@{$object->packages}), 5, 'packages 9');
is($object->packages->[0], "Zero", 'packages 10');
is($object->packages->[1], "One", 'packages 11');
is($object->packages->[2], "Two", 'packages 12');
is($object->packages->[3], "Three", 'packages 13');
is($object->packages->[4], "Four", 'packages 14');
