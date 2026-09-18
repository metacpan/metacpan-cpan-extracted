package ResidualOnly;

use strict;
use warnings;

sub reverse_words {
    my ($text) = @_;
    my @parts = split /\s+/, ($text // '');
    return join ' ', reverse @parts;
}

1;

__END__

=head1 NAME

t/fixtures/app_lib/ResidualOnly.pm - fixture: a residual (rarely-taken) runtime-only code path reached through a companion module

=head1 PURPOSE

A companion library for app_entry.pl: one sub that reverses whitespace-separated words, reached only via app_entry.pl's C<residual-only> subcommand, to test a code path that is reachable but not exercised by every entrypoint invocation.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - a residual (rarely-taken) runtime-only code path reached through a companion module -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Loaded by t/fixtures/app_entry.pl; C<reverse_words> is only actually called when app_entry.pl is invoked with the C<residual-only> subcommand.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/app_lib/ResidualOnly.pm

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/app_lib/ResidualOnly.pm -o /tmp/out && /tmp/out

=cut
