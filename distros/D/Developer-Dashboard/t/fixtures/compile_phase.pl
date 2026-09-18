use strict;
use warnings;

BEGIN {
    package PAX::Fixture::CompilePhase;
    our $BEGIN_RAN = 1;
}

sub marker {
    return $PAX::Fixture::CompilePhase::BEGIN_RAN;
}

die "BEGIN did not run" unless marker();
1;

__END__

=head1 NAME

t/fixtures/compile_phase.pl - fixture: compile-time (BEGIN-phase) side effects surviving into runtime

=head1 PURPOSE

Defines a BEGIN block that sets a package variable, then dies unless a later sub confirms that BEGIN-time side effect actually ran before the rest of the file executed.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - compile-time (BEGIN-phase) side effects surviving into runtime -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: the file dies with "BEGIN did not run" if PAX's capture/compile pipeline fails to preserve BEGIN-phase execution order, so a bare non-zero exit from running it is itself the failure signal.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/compile_phase.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/compile_phase.pl -o /tmp/out && /tmp/out

=cut
