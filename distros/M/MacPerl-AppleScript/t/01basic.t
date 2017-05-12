# -*- perl -*-

use Test::More tests => 81;
use Test::Exception;

#
# can module get use'd ?
#
BEGIN { use_ok('MacPerl::AppleScript') };
use MacPerl::AppleScript;

#
# Existence of certain sub's
#
can_ok('MacPerl::AppleScript', 'new');
can_ok('MacPerl::AppleScript', 'execute');
can_ok('MacPerl::AppleScript', 'app');
can_ok('MacPerl::AppleScript', 'name');
can_ok('MacPerl::AppleScript', 'parent');
can_ok('MacPerl::AppleScript', 'register_class');
can_ok('MacPerl::AppleScript', 'get_registered_class');
can_ok('MacPerl::AppleScript', 'convert_path');

#
# simple object behaviour tests -- not yet doing some applescript commands...
#
my $package   = "MacPerl::AppleScript";

my $app_name  = "StupidFooBarApp"; # hopefully not existing :-)
my $app_object;
lives_ok { $app_object = MacPerl::AppleScript->new($app_name) } "App Object simple construction";
is(ref($app_object), $package, "app object is of right class");
is($app_object->name(), "application \"$app_name\"", "correct App name given back");
is($app_object->app(), $app_object, "correct App Object given back");
is($app_object->parent(), undef, "app has no parent");
is("$app_object", $app_object->name(), "stringify App Object");

my $app2_object;
lives_ok { $app2_object = MacPerl::AppleScript->new("application \"$app_name\"") } "App Object 2 full name construction";
is($app2_object, $app_object, "second app object is identical to first");

my $app3_name = "CrazyFooBarApp";  # hopefully not existing :-)
my $app3_object;
lives_ok { $app3_object = MacPerl::AppleScript->new("application \"$app3_name\"") } "App Object 3 full name construction";
isnt($app3_object, $app_object, "really new app object created");
is(ref($app3_object), $package, "app object is of right class");
is($app3_object->name(), "application \"$app3_name\"", "correct App name given back");
is($app3_object->app(), $app3_object, "correct App Object given back");
is($app3_object->parent(), undef, "app has no parent");

my $obj_name  = "foo object 42 of application \"$app_name\"";
my $foo_object;
lives_ok { $foo_object = MacPerl::AppleScript->new($obj_name) } "Make new foo Object";
is(ref($foo_object), $package, "foo object is of right class");
is($foo_object->name(), $obj_name, "correct Obj name given back");
is($foo_object->app(), $app_object, "correct App Object given back");
is($foo_object->parent(), $app_object, "foo Object has right parent");

my $obj2_name = "foo object 42";
my $foo2_object;
lives_ok { $foo2_object = $app_object->new($obj2_name) } "foo2 Object relative to app object";
is(ref($foo2_object), $package, "foo2 object is of right class");
is($foo2_object->name(), "$obj2_name of $app_object", "correct Obj name given back");
is($foo2_object->app(), $app_object, "correct App Object given back");
is($foo2_object->parent(), $app_object, "foo2 Object has right parent");

my $app4_name = "DummyFooBarApp";  # hopefully not existing :-)
my $obj3_name = "foo object 42 of application \"$app4_name\"";
my $foo3_object;
lives_ok { $foo3_object = MacPerl::AppleScript->new($obj3_name) } "Make new foo3 Object";
is(ref($foo3_object), $package, "foo3 object is of right class");
is($foo3_object->name(), $obj3_name, "correct Obj name given back");
is($foo3_object->app()->name(), "application \"$app4_name\"", "correct App Object given back");
is($foo3_object->parent(), $foo3_object->app(), "foo3 Object has right parent");
isnt($foo3_object, $foo_object, "not identical to foo");
isnt($foo3_object, $foo2_object, "not identical to foo2");

my $obj4_name = "bar item 13 of $obj_name";
my $foo4_object;
lives_ok { $foo4_object = MacPerl::AppleScript->new($obj4_name) } "Make new foo4 Object";
is(ref($foo4_object), $package, "foo4 object is of right class");
is($foo4_object->name(), $obj4_name, "correct Obj name given back");
is($foo4_object->app(), "application \"$app_name\"", "correct App Object given back");
is($foo4_object->parent(), $foo_object, "foo4 Object has right parent: foo");

my $obj5_name = "dummy entry 17 of bar item 13";
my $foo5_object;
lives_ok { $foo5_object = $foo_object->new($obj5_name) } "foo5 Object relative to foo object";
is(ref($foo5_object), $package, "foo5 object is of right class");
is($foo5_object->name(), "$obj5_name of $foo_object", "correct Obj name given back");
is($foo5_object->app(), $foo_object->app(), "correct App Object given back");
is($foo5_object->parent()->parent(), $foo_object, "foo5 Object has right parent: foo");

#
# Define some registrations
#
lives_ok { $app_object->register_class('FooApp', 'MacPerl::FooAppClass') } "register fooapp";
lives_ok { $app_object->register_class('application "Bar App"', 'MacPerl::BarAppClass') } "register barapp";

lives_ok { $app_object->register_class('item of application "FooApp"', 'MacPerl::FooAppClass::Item') } "register fooapp-item";
lives_ok { $app_object->register_class('thing of application "FooApp"', 'MacPerl::FooAppClass::Thing') } "register fooapp-thing";

lives_ok { $app_object->register_class('item of application "Bar App"', 'MacPerl::BarAppClass::Item') } "register barapp-item";
lives_ok { $app_object->register_class('thing of item of application "Bar App"', 'MacPerl::BarAppClass::Thing') } "register barapp-item-thing";

lives_ok { $app_object->register_class('thing of item of application "XyzApp"', 'MacPerl::XyzAppClass::Thing') } "register xyzapp-item-thing";

#
# check if registrations behave OK
#
is($app_object->get_registered_class(['XxxApp']), undef, "unknown App 1");
is($app_object->get_registered_class(['application "XxxApp"']), undef, "unknown App 2");

#is($app_object->get_registered_class(['FooApp']), 'MacPerl::FooAppClass', "FooApp 1");
is($app_object->get_registered_class(['application "FooApp"']), 'MacPerl::FooAppClass', "FooApp 2");
is($app_object->get_registered_class(['x id 42','application "FooApp"']), undef, "x of FooApp");
is($app_object->get_registered_class(['item id 42','application "FooApp"']), 'MacPerl::FooAppClass::Item', "item of FooApp");
is($app_object->get_registered_class(['x "noname"','item id 42','application "FooApp"']), undef, "x of item of FooApp");
is($app_object->get_registered_class(['thing "noname"','item id 42','application "FooApp"']), undef, "thing of item of FooApp");
is($app_object->get_registered_class(['thing "noname"','application "FooApp"']), 'MacPerl::FooAppClass::Thing', "thing of FooApp");
is($app_object->get_registered_class(['thingy "noname"','application "FooApp"']), undef, "thingy FooApp");
is($app_object->get_registered_class(['thin g','application "FooApp"']), undef, "thin g of FooApp");
is($app_object->get_registered_class(['thin id 42','application "FooApp"']), undef, "thin of FooApp");
is($app_object->get_registered_class(['x id 0815','thing "noname"','application "FooApp"']), undef, "x of thing of FooApp");


# is($app_object->get_registered_class(['Bar App']), 'MacPerl::BarAppClass', "BarApp 1");
is($app_object->get_registered_class(['application "Bar App"']), 'MacPerl::BarAppClass', "BarApp 2");
is($app_object->get_registered_class(['x id 42','application "Bar App"']), undef, "x of BarApp");
is($app_object->get_registered_class(['item id 42','application "Bar App"']), 'MacPerl::BarAppClass::Item', "item of BarApp");
is($app_object->get_registered_class(['x "noname"','item id 42','application "Bar App"']), undef, "x of item of BarApp");
is($app_object->get_registered_class(['thing "noname"','item id 42','application "Bar App"']), 'MacPerl::BarAppClass::Thing', "thing of item of BarApp");
is($app_object->get_registered_class(['thing "noname"','application "Bar App"']), undef, "thing of BarApp");

is($app_object->get_registered_class(['XyzApp']), undef, "Xyz App 1");
is($app_object->get_registered_class(['application "XyzApp"']), undef, "Xyz App 2");
is($app_object->get_registered_class(['x id 42','application "XyzApp"']), undef, "x of XyzApp");
is($app_object->get_registered_class(['item id 42','application "XyzApp"']), undef, "item of XyzApp");
is($app_object->get_registered_class(['thing id 42','application "XyzApp"']), undef, "thing of XyzApp");
is($app_object->get_registered_class(['thing "noname"','item id 42','application "XyzApp"']), 'MacPerl::XyzAppClass::Thing', "thing of item of XyzApp");

#
# test Pathname behaviour
#

# too trivial in the moment :-)
