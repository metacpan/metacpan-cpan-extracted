#!/usr/bin/env perl

use strict;
use warnings;

sub main {
    my (@argv) = @_;
    my $cmd = shift @argv || 'version';

    if ($cmd eq 'version') {
        print "0.2.0\n";
        return 0;
    }

    print STDERR "unknown command: $cmd\n";
    return 2;
}

exit main(@ARGV) unless caller;

1;

__END__

=head1 NAME

t/fixtures/main_wrapped_app.pl - fixture: a main-sub-wrapped entrypoint, rather than bare top-level script code

=head1 PURPOSE

A tiny CLI app whose entrypoint logic lives in a named C<main> sub, invoked only when the file runs as a script (guarded by C<unless caller>) rather than unconditionally at file scope.

=head1 WHY IT EXISTS

Ported from PAX's own upstream fixture corpus as part of DD-882's vendoring
of the whole PAX compiler into C<Developer::Dashboard::Pax::*>, so the same
narrow edge case PAX's own maintainers already tested against - a main-sub-wrapped entrypoint, rather than bare top-level script code -
keeps being exercised against the vendored copy exactly as it was against
the original.

=head1 WHEN TO USE

Change this file only when the specific behavior it captures needs to
change. Add a new, separate fixture for a different edge case rather than
widening this one's scope - each fixture in this directory is deliberately
narrow.

=head1 HOW TO USE

Built and run via C<pax build>/C<pax run> against this file as an
entrypoint, driven from t/183-pax-cli-build-run-contract.t. Its C<version> subcommand prints a version string and exits 0; any other argument prints an "unknown command" message to stderr and exits 2 - both paths are worth exercising once compiled.

=head1 WHAT USES IT

t/183-pax-cli-build-run-contract.t, exercising the vendored PAX compiler's
handling of this specific case during build and run.

=head1 EXAMPLES

Running it interpreted, the baseline behavior a compiled version must match:

    perl t/fixtures/main_wrapped_app.pl

Building and running it through the vendored PAX compiler:

    pax build t/fixtures/main_wrapped_app.pl -o /tmp/out && /tmp/out

=cut
