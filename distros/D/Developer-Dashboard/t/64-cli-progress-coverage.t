#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::CLI::Progress;

# Hermetic, config-independent runtime. The progress renderer touches no layer
# on disk, but we still isolate HOME and the working directory so a stray
# .developer-dashboard layer under the real home can never influence the run.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

# Helper: build a progress board whose output is captured into an in-memory
# buffer so rendering never leaks onto the test's own STDERR.
sub make_progress {
    my (%extra) = @_;
    my $buffer = '';
    open my $stream, '>', \$buffer or die "Unable to open in-memory stream: $!";
    my $progress = Developer::Dashboard::CLI::Progress->new(
        title  => 'coverage progress',
        tasks  => [ { id => 'task-a', label => 'Task A' } ],
        stream => $stream,
        %extra,
    );
    return ( $progress, \$buffer );
}

# Line 62 (or_3, !l&&r): add_tasks receives a real ARRAY reference that happens
# to be empty, so ref() ne 'ARRAY' is false but !@{$tasks} is true.
{
    my ($progress) = make_progress();
    is( $progress->add_tasks( [] ), 1, 'add_tasks returns true for an empty (but valid) array reference' );
    is_deeply(
        $progress->{order},
        ['task-a'],
        'add_tasks with an empty array reference leaves the existing task order untouched',
    );
}

# Line 94 (and_3, l&&!r): detail_lines carries fewer entries than a configured,
# defined, positive cap, so defined($max) is true but @detail_lines > $max is
# false and no trailing slice happens.
{
    my ($progress) = make_progress( max_detail_lines => 5 );
    $progress->update(
        {
            task_id      => 'task-a',
            status       => 'running',
            detail_lines => [ 'first line', 'second line' ],
        }
    );
    is_deeply(
        $progress->{tasks}{'task-a'}{detail_lines},
        [ 'first line', 'second line' ],
        'detail_lines under the configured cap are stored verbatim without truncation',
    );
}

# Line 103 (and_3, !l): a single detail_line update on a board with no cap
# configured means _detail_line_limit returns undef, so defined($max) is false
# and the append path keeps every recorded line.
{
    my ($progress) = make_progress();
    $progress->update(
        {
            task_id     => 'task-a',
            status      => 'running',
            detail_line => 'only line',
        }
    );
    is_deeply(
        $progress->{tasks}{'task-a'}{detail_lines},
        ['only line'],
        'a single detail_line append with no configured cap keeps the line uncapped',
    );
}

# Line 171 (branch true): _detail_line_limit guards against being called on an
# object that never recorded a max_detail_lines key at all.
{
    my $bare = bless {}, 'Developer::Dashboard::CLI::Progress';
    is(
        $bare->_detail_line_limit,
        undef,
        '_detail_line_limit returns undef when the max_detail_lines key is absent entirely',
    );
}

# Line 174 (and_3, !l): a defined but non-numeric cap fails the /^\d+$/ test, so
# the regex short-circuits the && and the method falls back to the default 10.
{
    my ($progress) = make_progress( max_detail_lines => 'lots' );
    is(
        $progress->_detail_line_limit,
        10,
        '_detail_line_limit falls back to 10 for a defined but non-numeric cap',
    );
}

# Sanity: a defined, positive numeric cap is honoured and actually trims the
# rolling detail-line window, confirming the fallback above is a genuine branch.
{
    my ($progress) = make_progress( max_detail_lines => 2 );
    $progress->update(
        {
            task_id      => 'task-a',
            status       => 'running',
            detail_lines => [ 'one', 'two', 'three' ],
        }
    );
    is_deeply(
        $progress->{tasks}{'task-a'}{detail_lines},
        [ 'two', 'three' ],
        'a numeric cap trims detail_lines to the most recent entries',
    );
}

# DD-394 characterization pin: render records the rendered line count so the
# dynamic redraw can rewind exactly that many terminal lines. The count is
# derived from splitting the rendered board on newlines, and the split-derived
# list can never contain undef, so the count must include interior blank lines
# and must exclude the single trailing newline that render_text always appends.
# This block pins the exact count before and after the redundant definedness
# filter is removed from that expression.
{
    my ( $progress, $buffer ) = make_progress( dynamic => 1 );
    is(
        $progress->{last_rendered_line_count},
        2,
        'render counts every rendered board line and ignores the trailing newline',
    );

    my $board = $progress->render_text;
    is( scalar( () = $board =~ /\n/g ), 2, 'the rendered board carries one newline per counted line' );
    like( $board, qr/\n\z/, 'render_text terminates the board with exactly one trailing newline' );

    $progress->update( { task_id => 'task-a', status => 'running', detail_lines => [ 'one', 'two' ] } );
    is(
        $progress->{last_rendered_line_count},
        4,
        'render recounts the board after detail lines grow it',
    );

    my $rewinds = () = ${$buffer} =~ /\e\[1A\e\[2K/g;
    is( $rewinds, 2, 'the dynamic redraw rewound exactly the previously counted line count' );
}

# DD-394 characterization pin: an interior blank line is a real rendered line
# and must be counted, which is the one case where the removed defined() filter
# could have looked load-bearing — split yields an empty string there, never
# undef, so the count is unchanged by the simplification.
{
    my ($progress) = make_progress( title => "banner\n\ntrailer" );
    is(
        $progress->{last_rendered_line_count},
        4,
        'render counts interior blank lines produced by a multi-line title',
    );
}

# DD-394 acceptance: the simplified filters keep excluding empty fields from
# split-derived lists, which is the only filtering the removed defined() side
# ever contributed to.
{
    is_deeply(
        [ grep { $_ ne '' } split /:/, ':alpha::beta:' ],
        [ 'alpha', 'beta' ],
        'a split-derived non-empty filter still drops leading, interior, and trailing empty fields',
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/64-cli-progress-coverage.t - branch and condition coverage closure for the CLI progress renderer

=head1 PURPOSE

This test drives the remaining uncovered branch and condition sides of the
terminal progress-board renderer used by lifecycle commands. It exercises the
empty-array guard in task registration, both detail-line capping paths (a
configured numeric cap versus no cap at all), the absent-key guard in the cap
normalizer, and the non-numeric cap fallback, so every reachable decision in the
renderer is executed by the suite.

=head1 WHY IT EXISTS

The progress renderer normalizes its rolling detail-line cap and appends or
truncates task detail lines through several short-circuiting conditionals. Those
conditionals are hard to reach from the higher-level restart and stop flows
because the flows always configure a cap and always send well-formed events.
This file pins the underlap directly: it calls the renderer with an empty task
array, with detail counts on both sides of the cap, and with a cap that is
absent or non-numeric, so the coverage gate cannot silently regress when the
capping logic changes.

=head1 WHEN TO USE

Use this file when changing how the progress board registers late-discovered
tasks, how it stores or truncates per-task detail lines, or how it normalizes
the configured detail-line cap.

=head1 HOW TO USE

Run C<prove -lv t/64-cli-progress-coverage.t> while iterating on the renderer,
and keep it green under C<prove -lr t> and the coverage run before release.

=head1 WHAT USES IT

Developers during TDD, the full repository test suite, and the branch and
condition coverage gate all use this file to keep the progress renderer's
decision paths honestly exercised.

=head1 EXAMPLES

Example 1:

  prove -lv t/64-cli-progress-coverage.t

Run the focused progress-renderer coverage test by itself.

Example 2:

  perl -Ilib t/64-cli-progress-coverage.t

Run the same test standalone while confirming it stays warning-clean.

Example 3:

  prove -lr t

Put the renderer back through the whole suite before calling the work finished.

=cut
