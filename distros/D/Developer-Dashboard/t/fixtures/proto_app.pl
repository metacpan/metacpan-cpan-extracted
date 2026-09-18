use strict;
use warnings;

use lib 't/fixtures/app_lib';
use ProtoOps ();

print ProtoOps::constant_one(41, 99), "\n";

__END__

=head1 NAME

t/fixtures/proto_app.pl - fixture: subroutine prototypes affecting how a call site is parsed and compiled

=head1 PURPOSE

Calls ProtoOps::constant_one, a sub declared with an explicit Perl prototype (C<($$)>), so PAX's handling of prototype-sensitive call sites has a real application-level call to exercise.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - subroutine prototypes affecting how a call site is parsed and compiled -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Depends on t/fixtures/app_lib/ProtoOps.pm via a relative C<use lib>, so it must be built/run from a context where that library path resolves.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/proto_app.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/proto_app.pl -o /tmp/out && /tmp/out

=cut
