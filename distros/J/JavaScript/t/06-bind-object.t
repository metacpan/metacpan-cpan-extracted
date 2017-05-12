#!perl

package Foo;

use strict;
use warnings;

use Test::More tests => 14;
use Test::Exception;

use JavaScript;

sub new { return bless {}, __PACKAGE__; }

sub bar { 
    my $self = shift; 
    return 5;
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

# Create a new runtime
my $rt1 = new JavaScript::Runtime();

# Create a new context
my $cx1 = $rt1->create_context();

$cx1->bind_class(
        name => 'Foo',
        constructor => sub { return Foo->new(); },
        methods => {
            bar => \&Foo::bar,
            baz => \&Foo::baz,
        },
        properties => {
            std => 0,
            wrapped_value => {
                flags => JS_PROP_ACCESSOR,
                setter => \&Foo::setWrap,
                getter => \&Foo::getWrap,
            },  
        },
        package => 'Foo'
);

my $foo = new Foo();

lives_ok { $cx1->bind_object('FooSan', $foo) } "bound object FooSan ok";

isa_ok($cx1->eval("FooSan;"), "Foo", "returned object is-a Foo");

is($cx1->eval("FooSan.bar();"), 5, "Calling method bar() on bound object");

$cx1->eval(q{
FooSan.std = 1;
});

is($foo->{std}, 1, "Assignment to property in object");

$foo->{std} = 3;

is($cx1->eval(q{ FooSan.std }), 3, "Reading property in object");

$cx1->eval(q!
FooSan.wrapped_value = 1;
!);

ok($foo->{"setter_called"}, "Assignment to property with setter");

ok($foo->{wrapped} == 1, "Assigned value is 1");

ok($cx1 && ref($cx1), "Still have context after calling setter"); # somehow disappeared during development

$foo->{wrapped} = 2;

ok($cx1->eval(q{
    FooSan.wrapped_value
}) == 2, "Calling getter");
ok($foo->{"getter_called"}, "Reading from property with getter");

ok($cx1 && ref($cx1), "Still have context after calling getter"); # somehow disappeared during development

$foo->{"getter_called"} = 0;

$cx1->eval(q{
FooSan.wrapped_value = FooSan.wrapped_value + 1;
});
ok($foo->{"getter_called"}, "Calling getter and setter");

ok($cx1 && ref($cx1), "Still have context after both getter and setter"); # somehow disappeared during development

ok($foo->{wrapped} == 3, "Value is correct (3)");


