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

This staged update script owns one explicit phase of runtime update, bootstrap, and staged maintenance behavior. Read it when you need the real runtime side effects, logging, and failure behavior for that phase rather than inferring it from the higher-level command wrapper.

=head1 WHY IT EXISTS

It exists so the update pipeline stays explicit, inspectable, and testable one phase at a time. That keeps failures visible and avoids hiding important runtime changes inside one oversized installer step.

=head1 WHEN TO USE

Use this file when changing runtime update, bootstrap, and staged maintenance behavior, when debugging the staged update pipeline, or when the higher-level dashboard update flow fails and you need to isolate this phase.

=head1 HOW TO USE

Run it through C<dashboard update> for the supported path, or invoke the file directly from the source tree when you need to debug only this phase. Keep the phase explicit, idempotent where intended, and noisy on failure.

=head1 WHAT USES IT

The staged runtime update pipeline, update-manager verification, and contributors debugging install or bootstrap regressions use this file.

=head1 EXAMPLES

Example 1:

  prove -lv t/04-update-manager.t t/28-runtime-cpan-env.t

Rerun the focused update and runtime-local dependency tests after changing this phase.

Example 2:

  cpanm --installdeps --notest .

Compare the direct cpanm command with this wrapper when diagnosing dependency drift.

Example 3:

  dashboard update

Run the supported end-user path that can reach this update phase.

Example 4:

  perl updates/02-install-deps.pl

Invoke only this phase while debugging the update pipeline in a source checkout.

=for comment FULL-POD-DOC END

=cut
