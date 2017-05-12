package Sample::Simple::Baz;
# This file should get FULL coverage over every condition!

use strict; use warnings;

=over

=item foo

This is a sample function, as it can be observed: it's covered in POD too :)

=cut
sub foo {
    my ($a, $b) = @_;

    my $c = undef;

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
