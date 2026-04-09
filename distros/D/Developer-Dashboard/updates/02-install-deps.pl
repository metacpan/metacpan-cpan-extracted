#!/usr/bin/env perl

use strict;
use warnings;

use Capture::Tiny qw(capture);

my ( $cpanm, undef, $which_exit ) = capture {
    system 'which', 'cpanm';
    return $? >> 8;
};
chomp $cpanm;

if ( $which_exit != 0 || !$cpanm ) {
    print "cpanm not found; skipping dependency refresh\n";
    exit 0;
}

print "Refreshing Perl dependencies with cpanm\n";
system $cpanm, '--notest', '--installdeps', '.';

my $exit_code = $? >> 8;
exit $exit_code;

__END__

=head1 NAME

02-install-deps.pl - refresh Perl dependencies for Developer Dashboard

=head1 DESCRIPTION

This update script looks for C<cpanm> and, when available, refreshes the
repository dependencies with C<cpanm --notest --installdeps .>.

=for comment FULL-POD-DOC START

=head1 PURPOSE

Update script in the Developer Dashboard codebase. This file installs runtime-scoped Perl dependencies required by the current dashboard environment.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep update/bootstrap phases explicit, rerunnable, and separately testable.

=head1 WHEN TO USE

Use this file when you are working on the staged update/bootstrap pipeline or debugging update-time runtime preparation.

=head1 HOW TO USE

Run it through the dashboard update/bootstrap flow rather than inventing a parallel manual setup path. Keep the phase idempotent and explicit so reruns are safe.

=head1 WHAT USES IT

It is used by the runtime update/bootstrap pipeline, by the related update manager logic, and by tests that verify update behaviour.

=head1 EXAMPLES

  dashboard update

That higher-level command is the supported path that eventually reaches this staged update phase.

=for comment FULL-POD-DOC END

=cut
