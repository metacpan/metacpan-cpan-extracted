package AutoNativeMath;

use strict;
use warnings;

sub multiply {
    my ($left, $right) = @_;
    return $left * $right;
}

1;

__END__

=head1 NAME

t/fixtures/app_lib/AutoNativeMath.pm - fixture: automatic native-candidate detection when the candidate sub lives in a separate module

=head1 PURPOSE

A companion library for auto_native_app.pl: one multiply sub, used to test PAX's automatic native-candidate detection across a module boundary rather than within a single file.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - automatic native-candidate detection when the candidate sub lives in a separate module -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Loaded by t/fixtures/auto_native_app.pl via C<use lib 't/fixtures/app_lib'> - resolvable only when that relative library path is on C<@INC>.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/app_lib/AutoNativeMath.pm

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/app_lib/AutoNativeMath.pm -o /tmp/out && /tmp/out

=cut
