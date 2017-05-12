package Foo::Bar::1;

use Moo;
extends 'Foo::Bar::0';

has 'foo' => (
    is      => 'ro',
    default => sub { ( split m{::}, __PACKAGE__ )[-1] },
);

sub BUILDARGS {
    my ( $class, @args ) = @_;

    unshift @args, 'foo' if @args;
    return {@args};
}

sub BUILD {
    my ($self) = @_;

    push @Foo::Bar::0::build_order, __PACKAGE__;

    return;
}

1;
