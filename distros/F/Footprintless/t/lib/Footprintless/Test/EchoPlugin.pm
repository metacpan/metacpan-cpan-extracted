use strict;
use warnings;

package Footprintless::Test::EchoPlugin;

use parent qw(Footprintless::Plugin);

sub echo {
    my ( $self, @rest ) = @_;

    unless ( $self->{echo} ) {
        require Footprintless::Test::Echo;
        $self->{echo} = Footprintless::Test::Echo->new(@rest);
    }

    return $self->{echo};
}

sub factory_methods {
    my ($self) = @_;
    return {
        echo => sub {
            return $self->echo(@_);
        },
        echo_config => sub {
            return $self->{config};
        }
    };
}

1;
