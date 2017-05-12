package DessertTopping;

use strict;
use warnings;
use Lexical::Attributes;

has $.colour is ro;

sub new {
    bless \do {my $v} => shift;
}

method init {
    $.colour = shift;
    $self;
}

sub count_dessert_topping_keys {
    scalar keys %colour;
}


1;

__END__
