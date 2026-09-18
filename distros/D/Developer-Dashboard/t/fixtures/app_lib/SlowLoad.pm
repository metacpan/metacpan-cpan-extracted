package SlowLoad;

use strict;
use warnings;

our $LOADED = ($LOADED // 0) + 1;

sub message {
    return "slowload-ready";
}

1;

__END__

=head1 NAME

t/fixtures/app_lib/SlowLoad.pm - fixture: a plain, always-loaded companion module (the baseline against which HybridLoad's mixed loading is compared)

=head1 PURPOSE

A companion library for app_entry.pl: tracks its own load count and exposes a single ready message, used as the default (C<status>) code path to test straightforward module-load and call behavior.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - a plain, always-loaded companion module (the baseline against which HybridLoad's mixed loading is compared) -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Loaded by t/fixtures/app_entry.pl and called by its default C<status> subcommand; C<$LOADED> tracks how many times the module itself has been loaded.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/app_lib/SlowLoad.pm

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/app_lib/SlowLoad.pm -o /tmp/out && /tmp/out

=cut
