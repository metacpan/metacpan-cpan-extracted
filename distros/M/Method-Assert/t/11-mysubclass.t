#!perl -T

use Test::More tests => 14;
use Test::Exception;
use Test::NoWarnings;

use lib 't/lib';

use MySubClass;

# Test class method (constructor)
lives_ok { MySubClass->new() } "MySubClass->new() should not die";
dies_ok { MySubClass->new->new } "new() as instance method should die";
dies_ok { MySubClass::new() } "Calling MySubClass::new() as a function should die because it doesn't exist";

# Test class method
lives_ok { MySubClass->instance_count() } "MySubClass->instance_count() should not die";
dies_ok { MySubClass->new->instance_count() } "instance_count() as instance method should die";
dies_ok { MySubClass::instance_count() } "Calling instance_count() as a function should die because it doesn't exist";

# Test instance method
dies_ok { MySubClass->new->output() } "Calling output() as an instance method should die because it uses a class method in the wrong way";
dies_ok { MySubClass->output() } "Calling output() as a class method should die";
dies_ok { MySubClass::output() } "Calling output() as a function should die";

# Test class method from subclass
lives_ok { MySubClass->get_default_output_fh() } "get_default_output_fh() called as class method should not die";
dies_ok { MySubClass->new->get_default_output_fh() } "get_default_output_fh() called as an instance method should die";

# Test instance method that defaults to overridden class method result
dies_ok { MySubClass->new->get_output_fh() } "get_output_fh() called as instance method should die because it uses class method in the wrong way";
lives_ok { MySubClass->new->set_output_fh(\*STDOUT)->get_output_fh() } "get_output_fh() called as instance method (after set_output_fh) should not die";
