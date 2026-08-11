#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PageRuntime::StreamHandle;

# Hermetic, isolated runtime: an empty HOME that is also the CWD so any layer
# discovery resolves under the throwaway directory and never the real home.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
isa_ok( $paths, 'Developer::Dashboard::PathRegistry', 'hermetic path registry constructs under the temp home' );

# TIEHANDLE with an explicit writer callback: the `$args{writer} || sub { }`
# condition takes its left (writer-supplied) side.
my @chunks;
my $with_writer = Developer::Dashboard::PageRuntime::StreamHandle->TIEHANDLE(
    writer => sub { push @chunks, $_[0] },
);
isa_ok( $with_writer, 'Developer::Dashboard::PageRuntime::StreamHandle', 'TIEHANDLE returns a blessed stream handle when a writer is supplied' );
is( ref $with_writer->{writer}, 'CODE', 'TIEHANDLE keeps the supplied writer callback' );

# TIEHANDLE with no writer: the condition falls through to the default
# `sub { }` no-op writer (left false, right true).
my $default = Developer::Dashboard::PageRuntime::StreamHandle->TIEHANDLE;
isa_ok( $default, 'Developer::Dashboard::PageRuntime::StreamHandle', 'TIEHANDLE still returns a handle when no writer is supplied' );
is( ref $default->{writer}, 'CODE', 'TIEHANDLE installs a default no-op writer when none is supplied' );
is( $default->PRINT('ignored'), 1, 'PRINT succeeds against the default no-op writer' );

# PRINT joins parts and normalises undefined parts to the empty string.
@chunks = ();
is( $with_writer->PRINT( 'a', undef, 'b' ), 1, 'PRINT returns a true value' );
is( $chunks[-1], 'ab', 'PRINT joins parts and treats undef parts as empty strings' );

# PRINTF with a defined format: the `defined $format ? $format : ''` branch
# takes its true side.
@chunks = ();
is( $with_writer->PRINTF( '%s=%d', 'n', 7 ), 1, 'PRINTF returns a true value for a defined format' );
is( $chunks[-1], 'n=7', 'PRINTF formats output through the writer when a format is defined' );

# PRINTF with an undefined format: the ternary takes its FALSE side and
# sprintf runs against the empty-string fallback (no uninitialized warning).
@chunks = ();
is( $with_writer->PRINTF(undef), 1, 'PRINTF returns a true value even when the format is undefined' );
is( $chunks[-1], '', 'PRINTF falls back to an empty format string when the format is undefined' );

# CLOSE always reports success.
is( $with_writer->CLOSE, 1, 'CLOSE accepts close calls on the tied stream handle' );

# End-to-end through the actual tie interface so real print/printf dispatch is
# exercised, not just direct method calls.
@chunks = ();
{
    tie local *STREAM, 'Developer::Dashboard::PageRuntime::StreamHandle',
        writer => sub { push @chunks, $_[0] };
    print {*STREAM} 'streamed';
    printf {*STREAM} '%s!', 'done';
    close STREAM;
}
is( $chunks[0], 'streamed', 'tied print dispatches through PRINT to the writer' );
is( $chunks[1], 'done!',    'tied printf dispatches through PRINTF to the writer' );

done_testing;

__END__

=head1 NAME

t/61-streamhandle-coverage.t - branch and condition coverage for the streamed page-runtime output handle

=head1 PURPOSE

This test is the executable contract for the tied output handle that streams
bookmark runtime output. It pins the writer-default condition, the printf
empty-format fallback, and the print/close/tie dispatch so every branch and
condition path of the handle stays exercised and observable.

=head1 WHY IT EXISTS

It exists because the handle has two easily-missed paths that higher-level web
and CLI flows almost never take: constructing the handle without a writer (so
the default no-op callback is installed) and formatting with an undefined
format string (so the empty-string fallback runs instead of raising an
uninitialized-value warning). Those paths kept the module short of full branch
and condition coverage, and a code-only review misses them, so they earn a
dedicated, hermetic regression file.

=head1 WHEN TO USE

Use this file when changing the streamed-output handle's construction,
writer-forwarding, printf formatting, or close semantics, or when a coverage
run reports an uncovered branch or condition in the streaming handle.

=head1 HOW TO USE

Run C<prove -lv t/61-streamhandle-coverage.t> while iterating on the handle,
then keep it green under C<prove -lr t> and the coverage gate before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the Devel::Cover
coverage gate all rely on this file to keep the streamed-output handle's
behavior and coverage from regressing.

=head1 EXAMPLES

Example 1:

  prove -lv t/61-streamhandle-coverage.t

Run the focused streamed-handle coverage test by itself while changing the
handle.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/61-streamhandle-coverage.t

Exercise the same test while collecting coverage for the streamed-output
handle.

Example 3:

  prove -lr t

Put the change back through the entire repository suite before calling the work
finished.

=cut
