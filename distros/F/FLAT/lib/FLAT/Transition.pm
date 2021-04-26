# parent class - meant for interfaces to implement

package FLAT::Transition;
use strict;
use Carp;

sub new {
    croak("needs to be implemented");
}

sub does {
    croak("needs to be implemented");
}

sub add {
    croak("needs to be implemented");
}

sub delete {
    croak("needs to be implemented");
}

sub alphabet {
    croak("needs to be implemented");
}

sub as_string {
    croak("needs to be implemented");
}

1;
