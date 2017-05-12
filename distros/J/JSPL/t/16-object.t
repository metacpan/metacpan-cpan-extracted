#!perl
package Foo;

use strict;
use warnings;

use Test::More tests => 13;

use JSPL qw(:flags);

sub new {
    return bless {}, __PACKAGE__;
}

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
    $self->{"getter_called"}++;
    $self->{"wrapped"};
}

sub setWrap {
    my ($self,$value) = @_;
    $self->{"setter_called"}++;
    $self->{"wrapped"} = $value;
}

# Create a new runtime
my $rt1 = JSPL::Runtime->new();
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
                setter => Foo->can('setWrap'),
                getter => Foo->can('getWrap'),
            },  
        },
        package => 'Foo'
);

my $foo = Foo->new();

$cx1->bind_function(
    name => 'print', 
    func => sub { 
        my $dt = shift; 
        return undef; 
    }
);

ok($cx1->bind_object('FooSan', $foo), "Can bind FooSan");

$cx1->eval(q|
a = FooSan.bar();
print(a);
|);

ok(1);

$cx1->eval(q{
FooSan.std = 1;
});

ok($foo->{std} == 1, "std is one");

$foo->{std} = 3;

ok($cx1->eval(q{ FooSan.std }) == 3);

$cx1->eval(q!
FooSan.wrapped_value = 1;
!);

ok($foo->{"setter_called"});


ok($foo->{wrapped} == 1);


ok($cx1 && ref($cx1)); # somehow disappeared during development

$foo->{wrapped} = 2;

ok($cx1->eval(q{
    FooSan.wrapped_value
}) == 2);
ok($foo->{"getter_called"});

ok($cx1 && ref($cx1)); # somehow disappeared during development

$cx1->eval(q{
FooSan.wrapped_value = FooSan.wrapped_value + 1;
});
ok($foo->{"getter_called"});

ok($cx1 && ref($cx1)); # somehow disappeared during development

ok($foo->{wrapped} == 3);
