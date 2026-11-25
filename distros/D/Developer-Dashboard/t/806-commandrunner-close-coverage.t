#!/usr/bin/env perl
use strict;
use warnings;

# A scoped open redirect must be installed before CommandRunner is compiled:
# the production code deliberately uses CORE::close rather than a hookable
# close, so a pipe whose child exits nonzero gives a real close failure.
our $BROKEN_PID_FILE = 'fixture-command-close-failure.pid';

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if (@_ >= 3 && defined $_[2] && !ref $_[2]
            && $_[1] eq '>' && $_[2] eq $BROKEN_PID_FILE) {
            return CORE::open( $_[0], '|-', $^X, '-e',
                'while (<STDIN>) {} exit 7;' );
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[2 .. $#_] );
    };
}

use Test::More;
use lib 'lib';
use Developer::Dashboard::CommandRunner ();

my $ok = eval {
    Developer::Dashboard::CommandRunner::record_command_pid(
        $BROKEN_PID_FILE, 4242
    );
    1;
};
ok( !$ok, 'record_command_pid rejects a failed descriptor close' );
like( $@, qr/Unable to close collector command pid file/,
    'record_command_pid reports the close failure with its pidfile context' );

done_testing;

__END__

=head1 NAME

t/806-commandrunner-close-coverage.t - command PID close error

=head1 PURPOSE

Exercise the failed output-handle close error path for C<CommandRunner::record_command_pid>.

=head1 WHY IT EXISTS

Uses a private child pipe that exits nonzero to cover the otherwise rare PID-file close failure. The strict cross-platform coverage gate requires that this
failure be observed instead of assuming that a successful open guarantees
a successful close.

=head1 WHEN TO USE

Run this regression when changing the command or file persistence path
or its error-handling behavior.

=head1 HOW TO USE

  prove -lv t/806-commandrunner-close-coverage.t

Run under the repository coverage gate for all-metric verification.

=head1 WHAT USES IT

The developer test suite and the CI coverage gate.

=head1 EXAMPLES

  prove -lv t/806-commandrunner-close-coverage.t

Execute the failure-injection regression without touching real application files.

=cut
