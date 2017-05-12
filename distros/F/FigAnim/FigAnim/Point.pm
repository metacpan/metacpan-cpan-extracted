package Point;

use strict;
use warnings;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};

    $self->{x} = shift;
    $self->{y} = shift;

    bless ($self, $class);
    return $self;
}



1;
