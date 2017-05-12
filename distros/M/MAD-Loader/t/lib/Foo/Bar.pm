package Foo::Bar;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT_OK = qw{ foo };
our @EXPORT    = @EXPORT_OK;

my $_instance;

sub init {
    my $class = shift;
    my $foo = shift || 1;

    $Foo::_instance = bless { foo => $foo }, $class
      unless defined $Foo::_instance;

    return $Foo::_instance;
}

sub foo {
    return $Foo::_instance->{foo};
}

sub bar {
    my ($self) = @_;

    return $self->{foo};
}

1;
