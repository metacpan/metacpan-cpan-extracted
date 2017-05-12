package BadOOModule;

use strict;
use warnings;

sub new {
    my ( $class ) = @_;

    return bless {}, $class;
}

0; # I want to fail!
