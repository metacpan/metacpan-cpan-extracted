use strict;
use warnings;

package Footprintless::CommandRunner::Echo;

use parent qw(Footprintless::CommandRunner);

sub _run {
    my ( $self, $command, $runner_options ) = @_;
    print($command);
    return 0;
}

1;
