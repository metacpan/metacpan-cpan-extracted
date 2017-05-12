package Sample::Simple::Foo;
# This file should get NO coverage at all, it is not mentioned anywhere in unit tests.

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
