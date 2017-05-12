package Example::Div;
use strict;
use warnings;
use utf8;

sub div {
    my ($class, $lhs, $rhs) = @_;

    if ($rhs == 0) {
        return;
    }

    return do {
        use integer;
        return $lhs / $rhs;
    };
}

1;
