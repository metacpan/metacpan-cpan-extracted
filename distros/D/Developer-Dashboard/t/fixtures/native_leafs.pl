use strict;
use warnings;

sub add {
    my ($left, $right) = @_;
    return $left + $right;
}

sub subtract {
    my ($left, $right) = @_;
    return $left - $right;
}

sub multiply {
    my ($left, $right) = @_;
    return $left * $right;
}

sub greater_than {
    my ($left, $right) = @_;
    return $left > $right;
}

die "bad add" unless add(2, 3) == 5;
die "bad subtract" unless subtract(10, 3) == 7;
die "bad multiply" unless multiply(6, 7) == 42;
die "bad greater_than" unless greater_than(10, 3) == 1;
1;

__END__

=head1 NAME

t/fixtures/native_leafs.pl - fixture: small pure leaf functions that are good native-compilation candidates

=head1 PURPOSE

Defines four small, pure, argument-in/value-out arithmetic and comparison subs (add, subtract, multiply, greater_than) - the shape PAX's native-compilation path should treat as leaf functions.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - small pure leaf functions that are good native-compilation candidates -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with a specific message ("bad add", "bad subtract", etc.) if any of the four operations produces the wrong compiled/run result.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/native_leafs.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/native_leafs.pl -o /tmp/out && /tmp/out

=cut
