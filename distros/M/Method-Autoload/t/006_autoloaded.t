# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 8;

BEGIN { use_ok( 'Method::Autoload' ); }

my $object;
$object=Method::Autoload->new(packages=>[qw{My::Foo My::Bar}]);
isa_ok ($object, 'Method::Autoload');

is($object->foo, "My::Foo::foo", 'AUTOLOAD from inline package');
is($object->bar, "My::Bar::bar", 'AUTOLOAD from inline package');

my $hash=$object->autoloaded;
isa_ok($hash, "HASH");
isa_ok(scalar($object->autoloaded), "HASH");
is($object->autoloaded->{"foo"}, "My::Foo", 'autoloaded');
is($object->autoloaded->{"bar"}, "My::Bar", 'autoloaded');

package My::Foo;
sub foo {"My::Foo::foo"};
1;

package My::Bar;
sub foo {"My::Bar::foo"};
sub bar {"My::Bar::bar"};
1;
