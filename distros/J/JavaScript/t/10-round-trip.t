#!perl

package Foo;

use Test::More tests => 11;

use strict;
use warnings;

use JavaScript;

sub new {
    return bless {}, __PACKAGE__;
}

sub bar { 
    return bless { std => 5 }, __PACKAGE__;
}

sub baz {
    my $self = shift; 
    return "five"; 
}

sub getWrap {
    my ($self) = @_;
    $self->{"getter_called"} = 1;
    $self->{"wrapped"};
}

sub setWrap {
    my ($self,$value) = @_;
    $self->{"setter_called"} = 1;
    $self->{"wrapped"} = $value;
}

my $rt1 = JavaScript::Runtime->new();
my $cx1 = $rt1->create_context();

$cx1->bind_class(
                 name => 'Foo',
                 constructor => sub { return new Foo(); },
                 methods => {
                             bar => \&Foo::bar,
                             baz => \&Foo::baz,
                         },
                 properties => {
                                std => 0,
                                wrapped_value => {
                                                  flags => JS_PROP_ACCESSOR,
                                                  setter => Foo->can('setWrap'),
                                                  getter => Foo->can('getWrap'),
                                              },  
                            },
                 package => 'Foo'
             );

my $foo = Foo->new();
$foo->{std} = 10;

$cx1->bind_function(println => sub { print STDERR @_, "\n"; });
$cx1->bind_function( name => 'debug',
             func => sub { warn Dumper(@_) } );
$cx1->bind_function( name => 'isa_ok',
             func => sub { isa_ok($_[0], $_[1]) } );
$cx1->bind_function( name => 'is',
             func => \&is );
$cx1->bind_function( name => 'get_foo',
             func => sub { bless { std => 5}, 'Foo' } );

$cx1->bind_object('FooSan', $foo);

my $ret= $cx1->eval(q!
is(FooSan.std, 10);
isa_ok(FooSan, "Foo");
a = get_foo();
is(a.std, 5);

isa_ok(a, "Foo");

b = new Foo;
isa_ok(FooSan, "Foo");
isa_ok(b, "Foo");
var obj = { key1: 'ok', key2: 'ok' };

a;
!);
isa_ok($ret, 'Foo');



# throw an instance of a perl class bound into JS space _through_ js
# space. Make sure that (a) the instance in JS space looks like the
# thing we threw, and (b) that the instance that leaves is _still_
# the thing we threw.

# the thing we throw.
my $thing = bless { std => 5, wrapped => 4 }, 'Foo';

# a function to throw it.
$cx1->bind_function( name => 'throw_foo', func => sub { die $thing });

my $error = $cx1->eval(q!
var ret; // to return the object from JS space

try {
  throw_foo();
} catch (e) {
  println("Here");
  isa_ok( e, "Foo" ); // this test passes, but if run, breaks the next test
  is( e.std, 5, "std is correct" );
  is( e.wrapped_value, 4, "wrapped is correct" );
  ret = e;
}
ret;
!);

is( $error->{std}, 5, "error _leaves_ JS space ok");
