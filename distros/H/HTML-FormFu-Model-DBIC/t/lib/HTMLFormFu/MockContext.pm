package HTMLFormFu::MockContext;
use strict;
use warnings;

sub new {
    my ( $class, $args ) = @_;

    return bless $args, $class;
}

sub model {
    my ( $self ) = @_;

    return $self->{model}
}

1;

