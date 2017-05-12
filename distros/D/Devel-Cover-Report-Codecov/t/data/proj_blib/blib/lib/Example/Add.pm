package Example::Add;
use strict;
use warnings;
use utf8;

sub add {
    my ($class, $lhs, $rhs) = @_;
    return $lhs + $rhs;
}

1;
