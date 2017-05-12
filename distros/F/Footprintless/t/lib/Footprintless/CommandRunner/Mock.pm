use strict;
use warnings;

package Footprintless::CommandRunner::Mock;

use parent qw(Footprintless::CommandRunner);

use Carp;
use Log::Any;

my $logger = Log::Any->get_logger();

sub _init {
    my ( $self, $callback ) = @_;
    $self->Footprintless::CommandRunner::_init();
    $self->{callback} = $callback;
    return $self;
}

sub _run {
    my ( $self, $command, $runner_options ) = @_;
    return $self->{callback}( $command, $runner_options );
}

1;
