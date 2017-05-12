use strict;
use warnings;

package Footprintless::EchoCommandRunnerTestFactory;

use parent qw(Footprintless::Factory);

use Footprintless::CommandRunner::Echo;

sub command_runner {
    my ($self) = @_;

    unless ( $self->{command_runner} ) {
        $self->{command_runner} = Footprintless::CommandRunner::Echo->new();
    }

    return $self->{command_runner};
}

1;
