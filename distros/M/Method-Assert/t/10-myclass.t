#!perl -T

use Test::More tests => 13;
use Test::Exception;
use Test::NoWarnings;

use lib 't/lib';

use MyClass;

# Test class method (constructor)
lives_ok { MyClass->new() } "MyClass->new() should not die";
dies_ok { MyClass->new->new } "new() as instance method should die";
dies_ok { MyClass::new() } "Calling new as a function should die";
lives_ok { MyClass::new('MyClass') } "Calling new as a function with class name as first argument should not die";

# Test class method
lives_ok { MyClass->instance_count() } "MyClass->instance_count() should not die";
dies_ok { MyClass->new->instance_count() } "instance_count() as instance method should die";
dies_ok { MyClass::instance_count() } "Calling instance_count() as a function should die";
lives_ok { MyClass::instance_count('MyClass') } "Calling instance_count() as a function with class name as first argument should not die";

# Test instance method
lives_ok { MyClass->new->output() } "Calling output() as an instance method should not die";
dies_ok { MyClass->output() } "Calling output() as a class method should die";
dies_ok { MyClass::output() } "Calling output() as a function should die";
dies_ok { MyClass::output('MyClass') } "Calling output() as a function with class name as first argument should die";
