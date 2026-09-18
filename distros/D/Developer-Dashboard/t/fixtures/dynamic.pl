use strict;
use warnings;

our $AUTOLOAD;

sub AUTOLOAD {
    return "autoloaded";
}

my $code = '1 + 1';
my $result = eval "$code";
die "bad eval" unless $result == 2;
1;

__END__

=head1 NAME

t/fixtures/dynamic.pl - fixture: runtime dynamic behavior (AUTOLOAD and string eval) that a static compiler pass could mishandle

=head1 PURPOSE

Defines an AUTOLOAD handler and runs a string eval'd expression, then dies unless the eval'd result is correct.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - runtime dynamic behavior (AUTOLOAD and string eval) that a static compiler pass could mishandle -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Self-checking: dies with "bad eval" if the string-eval'd arithmetic does not produce the expected value once compiled and run.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/dynamic.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/dynamic.pl -o /tmp/out && /tmp/out

=cut
