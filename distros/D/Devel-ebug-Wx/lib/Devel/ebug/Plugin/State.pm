package Devel::ebug::Plugin::State;

use strict;
use base qw(Exporter);

our @EXPORT = qw(get_state set_state);

sub get_state {
    my( $self ) = @_;
    my $response = $self->talk( { command   => "get_state",
                                  } );
    return $response;
}

sub set_state {
    my( $self, $state ) = @_;
    my $response = $self->talk( { command   => "set_state",
                                  state     => $state,
                                  } );
    return $response;
}

1;
