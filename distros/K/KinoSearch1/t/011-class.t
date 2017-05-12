use strict;
use warnings;

use Test::More tests => 9;

package KinoSearch1::TestClass;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars( foo => 'correct', );
    __PACKAGE__->ready_get_set('foo');

}

sub die_an_abstract_death      { shift->abstract_death }
sub die_an_unimplemented_death { shift->unimplemented_death }
sub die_a_todo_death           { shift->todo_death }

our $version = $KinoSearch1::VERSION;

package MySubClass;
use base qw( Exporter KinoSearch1::TestClass );

package main;

# These should NOT be accessed.
our %instance_vars = (
    foo => 'wrong',
    bar => 'wrong',
);

my $verify_version = defined $KinoSearch1::TestClass::version;
is( $verify_version, 1,
          "Using this class should grant access to "
        . "package globals in the KinoSearch1:: namespace" );

can_ok( 'KinoSearch1::Util::Class', 'new' );

my $util_class_object = KinoSearch1::Util::Class->new();
is( ref $util_class_object, 'KinoSearch1::Util::Class',
    "constructor works." );

my $test_obj = KinoSearch1::TestClass->new;
is( $test_obj->{foo}, 'correct', "Inheritance works as expected" );

eval { $test_obj->die_an_abstract_death };
like( $@, qr/abstract/i,
    "abstract_death produces a meaningful error message" );

eval { $test_obj->die_a_todo_death };
like( $@, qr/todo/i, "todo_death produces a meaningful error message" );

eval { $test_obj->die_an_unimplemented_death };
like( $@, qr/unimplemented/i,
    "unimplemented_death produces a meaningful error message" );

my $subclassed_obj = MySubClass->new( foo => 'boo' );

is( $subclassed_obj->get_foo, "boo",
    "KinoSearch1 objects can be subclassed outside the KinoSearch1 hierarchy"
);

$subclassed_obj->set_foo("hoo");
is( $subclassed_obj->get_foo, "hoo",
    "ready_get_set creates valid setter and getter" );
