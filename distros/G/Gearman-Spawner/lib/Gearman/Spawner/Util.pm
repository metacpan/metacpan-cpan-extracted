package Gearman::Spawner::Util;

use strict;
use warnings;

sub method2function {
    my $class = shift;
    my $name = shift;
    return $class . '::' . $name;
}

1;
