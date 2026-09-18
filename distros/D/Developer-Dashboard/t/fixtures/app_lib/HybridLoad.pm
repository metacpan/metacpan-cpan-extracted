package HybridLoad;

use strict;
use warnings;

our $LOADED = ($LOADED // 0) + 1;
our $SOURCE_FALLBACK_LOADED = 0;

sub fast_message {
    return "hybrid-fast";
}

sub slow_message {
    my ($value) = @_;
    $SOURCE_FALLBACK_LOADED = 1;
    my @parts = split /:/, ($value // '');
    return join ':', reverse @parts;
}

1;

__END__

=head1 NAME

t/fixtures/app_lib/HybridLoad.pm - fixture: mixed eager and lazy module-load paths, tracked via package-level state ($LOADED, $SOURCE_FALLBACK_LOADED)

=head1 PURPOSE

A companion library for app_entry.pl: tracks its own load count and exposes both an always-fast path and a path that only runs once a slower/fallback branch executes, to test mixed eager and lazy load behavior.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - mixed eager and lazy module-load paths, tracked via package-level state ($LOADED, $SOURCE_FALLBACK_LOADED) -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Loaded by t/fixtures/app_entry.pl; C<fast_message> is always reachable, while C<slow_message> sets C<$SOURCE_FALLBACK_LOADED> as a side effect the first time it runs.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/app_lib/HybridLoad.pm

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/app_lib/HybridLoad.pm -o /tmp/out && /tmp/out

=cut
