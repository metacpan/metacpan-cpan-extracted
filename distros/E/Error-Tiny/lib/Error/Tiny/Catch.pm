package Error::Tiny::Catch;

use strict;
use warnings;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{handler} = $params{handler};
    $self->{class}   = $params{class};

    Carp::croak('class is required') unless $self->{class};

    return $self;
}

sub handler { $_[0]->{handler} }
sub class   { $_[0]->{class} }

1;
