package FloorWax;

use strict;
use warnings;
use Lexical::Attributes;

has $.colour is ro;
my @dead_colours;

sub new {
    bless \do {my $v} => shift;
}

method init {
    $.colour = shift;
    $self;
}

sub count_floor_wax_keys {
    scalar keys %colour;
}

method DESTRUCT {
    push @dead_colours => $.colour;
}

sub dead_colours {
    @dead_colours;
}

1;

__END__
