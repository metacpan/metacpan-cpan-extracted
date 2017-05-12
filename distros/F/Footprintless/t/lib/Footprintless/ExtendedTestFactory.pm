use strict;
use warnings;

package Footprintless::ExtendedTestFactory;

use parent qw(Footprintless::Factory);

sub foo {
    my ( $self, $arg ) = @_;
    return $arg;
}

1;
