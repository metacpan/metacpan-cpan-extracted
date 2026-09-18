use strict;
use warnings;

sub add {
    my ($left, $right) = @_;
    return $left + $right;
}

our $MUTATED = 0;

sub mutate_symbols {
    no strict 'refs';
    *dynamic_symbol = sub { return 1 };
    $MUTATED = 1;
    return $MUTATED;
}

die "bad add" unless add(2, 3) == 5;
1;

__END__

=head1 NAME

t/fixtures/mutation.pl - fixture: runtime symbol-table mutation (typeglob installation) happening inside a sub body, not at file scope

=head1 PURPOSE

Defines a sub that mutates package state and installs a new symbol-table entry at runtime via a typeglob assignment inside a sub, alongside a plain arithmetic sub used as a self-check.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - runtime symbol-table mutation (typeglob installation) happening inside a sub body, not at file scope -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with "bad add" if the compiled/run C<add(2, 3)> is not 5; C<mutate_symbols> is exercised separately by callers that need the dynamic-symbol behavior.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/mutation.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/mutation.pl -o /tmp/out && /tmp/out

=cut
