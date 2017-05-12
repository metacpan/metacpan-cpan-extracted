# NAME

Devel::TimeStats - Timing Statistics Class (Catalyst::Stats fork)

# SYNOPSIS

    use Devel::TimeStats;

    my $stats = Devel::TimeStats->new;

    $stats->enable(1);
    $stats->profile($comment);
    $stats->profile(begin => $block_name, comment =>$comment);
    $stats->profile(end => $block_name);
    $elapsed = $stats->elapsed;
    $report = $stats->report;
    @report = $stats->report;

# DESCRIPTION

This module is a fork of Catalyst::Stats, a timing statistics module.
Tracks elapsed time between profiling points and (possibly nested) blocks.

Typical usage might be like this:

    my $stats = Devel::TimeStats->new;
        

    $stats->profile( begin => 'interesting task' );
    

    run_step_1();
    $stats->profile( 'completed step 1' );
    

    run_step_2();
    $stats->profile( 'completed step 2' );
    

    run_step_3();
    $stats->profile( 'completed step 3' );
    

    run_step_4();
    $stats->profile( 'completed step 4' );
    

    run_step_5();
    $stats->profile( 'completed step 5' );
    

    # ... time spent here also accounted in the 'interesting task' block
    

    $stats->profile( end => 'interesting task' );
    

    print scalar $stats->report;

example report:

    .---------------------+-----------+------.
    | Action              |   Time    | %    |   # percentage helps blaming 
    +---------------------+-----------+------+
    | interesting task    | 0.661000s | 100% |   
    |  - completed step 1 | 0.001000s |  0%  |
    |  - completed step 2 | 0.010000s |  2%  |   # took >= 10ms, yellow (by default)
    |  - completed step 3 | 0.050000s |  8%  |   # took >= 50ms, bright yellow (by default)
    |  - completed step 4 | 0.100000s | 15%  |   # took >= 100ms, red (by default)
    |  - completed step 5 | 0.500000s | 76%  |   # took >= 500ms, bright red (by default)
    `---------------------+-----------+------'

You can configure the ["color\_map"](#color\_map) and ["percentage\_decimal\_precision"](#percentage\_decimal\_precision).

# METHODS

## new

Constructor.

    $stats = Catalyst::Stats->new(%options);

Valid options:

- `enable`

    Default `1`

- `color_map`

    A hashref mapping a duration threshold (in seconds) to a color. 
    Default:

        {
            '0.01' => 'yellow3',
            '0.05' => 'yellow1',
            '0.1'  => 'red3',
            '0.5'  => 'red1',
        }    

    See ["COLORS AND ATTRIBUTES" in Term::ExtendedColor](http://search.cpan.org/perldoc?Term::ExtendedColor#COLORS AND ATTRIBUTES).

- `percentage_decimal_precision`

    How many decimal places for the percentage column. 
    Default `0`.

## enable

    $stats->enable(0);
    $stats->enable(1);

Enable or disable stats collection.  By default, stats are enabled after object creation.

## profile

    $stats->profile($comment);
    $stats->profile(begin => $block_name, comment =>$comment);
    $stats->profile(end => $block_name);

Marks a profiling point.  These can appear in pairs, to time the block of code
between the begin/end pairs, or by themselves, in which case the time of
execution to the previous profiling point will be reported.

The argument may be either a single comment string or a list of name-value
pairs.  Thus the following are equivalent:

    $stats->profile($comment);
    $stats->profile(comment => $comment);

The following key names/values may be used:

- begin => ACTION

    Marks the beginning of a block.  The value is used in the description in the
    timing report.

- end => ACTION

    Marks the end of the block.  The name given must match a previous 'begin'.
    Correct nesting is recommended, although this module is tolerant of blocks that
    are not correctly nested, and the reported timings should accurately reflect the
    time taken to execute the block whether properly nested or not.

- comment => COMMENT

    Comment string; use this to describe the profiling point.  It is combined with
    the block action (if any) in the timing report description field.

- uid => UID

    Assign a predefined unique ID.  This is useful if, for whatever reason, you wish
    to relate a profiling point to a different parent than in the natural execution
    sequence.

- parent => UID

    Explicitly relate the profiling point back to the parent with the specified UID.
    The profiling point will be ignored if the UID has not been previously defined.

Returns the UID of the current point in the profile tree.  The UID is
automatically assigned if not explicitly given.

## created

    ($seconds, $microseconds) = $stats->created;

Returns the time the object was created, in `gettimeofday` format, with
Unix epoch seconds followed by microseconds.

## elapsed

    $elapsed = $stats->elapsed

Get the total elapsed time (in seconds) since the object was created.

## report

    print $stats->report ."\n";
    $report = $stats->report;
    @report = $stats->report;

In scalar context, generates a textual report.  In array context, returns the
array of results where each row comprises:

    [ depth, description, time, rollup, percentage ]

The depth is the calling stack level of the profiling point.

The description is a combination of the block name and comment.

The time reported for each block is the total execution time for the block, and
the time associated with each intermediate profiling point is the elapsed time
from the previous profiling point.

The 'rollup' flag indicates whether the reported time is the rolled up time for
the block, or the elapsed time from the previous profiling point.

The percentage of total time (floating-point number).

# COMPATIBILITY METHODS

Some components might expect the stats object to be a regular Tree::Simple object.
We've added some compatibility methods to handle this scenario:

## accept

## addChild

## setNodeValue

## getNodeValue

## traverse

# SEE ALSO

[Catalyst::Stats](http://search.cpan.org/perldoc?Catalyst::Stats)

# THANKS TO

Catalyst Contributors

# COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz <cafe@q1software.com>
