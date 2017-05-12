package Foo;

use strict;
use warnings;

sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return $self;
}

sub not_called {
}

sub baz {
    my $self = shift;
    my ($param, $param2) = @_;

    if ($param && $param2) {
        return 1;
    }
    elsif ($param > 10) {
        return 10;
    }
    else {
        return 0;
    }
}

sub bar {
    my $self = shift;
    my ($param) = @_;

    if ($param) {
        return 1;
    }

    return 0;
}

1;
