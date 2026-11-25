#!/usr/bin/env perl
use strict;
use warnings;

# Redirect exactly one File::write destination into a real child pipe that
# reads its input and exits nonzero. Its close then fails portably, without
# relying on filesystem permissions or /dev/full.
our $BROKEN_FILE = 'fixture-file-close-failure';

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if (@_ >= 3 && defined $_[2] && !ref $_[2] && defined $_[1]
            && $_[1] eq '>' && $_[2] eq $BROKEN_FILE) {
            return CORE::open( $_[0], '|-', $^X, '-e',
                'while (<STDIN>) {} exit 7;' );
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[2 .. $#_] );
    };
}

use Test::More;
use lib 'lib';
use Developer::Dashboard::File ();

{
    no warnings 'redefine';
    local *Developer::Dashboard::File::_resolve_file = sub { return $BROKEN_FILE };
    my $ok = eval {
        Developer::Dashboard::File->write($BROKEN_FILE, 'payload');
        1;
    };
    ok( !$ok, 'File::write rejects a real failed descriptor close' );
    like( $@, qr/Unable to close \Q$BROKEN_FILE\E/,
        'File::write reports the close failure and intended path' );
}

done_testing;

__END__

=head1 NAME

t/807-file-write-close-coverage.t - file write close error

=head1 PURPOSE

Exercise the failed output-handle close error path for C<File::write>.

=head1 WHY IT EXISTS

Uses a private child pipe that exits nonzero to cover the otherwise rare file write close failure. The strict cross-platform coverage gate requires that this
failure be observed instead of assuming that a successful open guarantees
a successful close.

=head1 WHEN TO USE

Run this regression when changing the command or file persistence path
or its error-handling behavior.

=head1 HOW TO USE

  prove -lv t/807-file-write-close-coverage.t

Run under the repository coverage gate for all-metric verification.

=head1 WHAT USES IT

The developer test suite and the CI coverage gate.

=head1 EXAMPLES

  prove -lv t/807-file-write-close-coverage.t

Execute the failure-injection regression without touching real application files.

=cut
