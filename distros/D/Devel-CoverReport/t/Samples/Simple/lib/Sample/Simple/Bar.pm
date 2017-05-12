package Sample::Simple::Bar;
# This file should get SOME coverage.

use strict; use warnings;

sub foo {
    my ($a, $b) = @_;

    my $c;

    if ($a or $b) {
        if ($a) {
            $c = $a;
        }
        else {
            $c = $b;
        }
    }

    if ($c > 5 and $c < 10) {
        $c = 10 * $c;
    }

    return $c;
}

1;
