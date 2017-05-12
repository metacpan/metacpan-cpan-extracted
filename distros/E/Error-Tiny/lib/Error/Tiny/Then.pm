package Error::Tiny::Then;

use strict;
use warnings;

require Carp;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{handler} = $params{handler};

    Carp::croak('handler is required') unless $self->{handler};

    return $self;
}

sub handler { $_[0]->{handler} }

1;
