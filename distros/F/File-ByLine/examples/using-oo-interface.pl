#!/usr/bin/perl

#
# File::ByLine makes easy stuff really easy - but here's an example of a
# slightly more complicated thing it also makes easy.
#

#
# Demonstration of more advanced abilities of File::ByLine
#
# PROBLEM -
#
# Quick, write a perl program that looks for your name in all *.pl and
# *.txt files in your home directory.
#
# Use 8 cores of your CPU to do the looking (so you need 8 threads/processes,
# but you should limit your processes/threads to 8 active ones.
#
# You should skip any file the process doesn't have permission to read.
#
# Catch all open() error codes and die.
#


#
# SOLUTION -
#
# First, some boilerplate, to use function signatures and modernish Perl
# features, which we'll do for both solutions:
#
use v5.22;
use strict;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

#
# Test harness - if "hard" is passed as the first argument on the
# command line, run the sub hard(). Otherwise run easy().
#
if ( ($ARGV[0] // '') eq 'hard' ) {
    hard();
} else {
    easy();
}

#
# The EASY Solution, using File::ByLine:
#
# We instantiate a ByLine object.  We'll need extended_info to get the
# file name in the ->map() method (as the second parameter).  We pass a
# list of files to read. We inform it we want 8 way parallization. And
# we enable skipping unreadable files.
#
# Then we do a map on all the files (last line of sub), and, if the line
# matches, we replace the element in question with the filename
# (info->{filename}).  Otherwise we return nothing.
#
# We take these results, sort them, and make them unique.  We then print
# them in a list.
#
# This isn't trivial or particularly efficient, but it's easy to write.
# But even though it's not super efficient, it's more efficient than the
# next solution and took 1/2 the wall time as the solution not using
# File::ByLine.
#
sub easy {
    use File::ByLine;
    use List::Util qw(uniqstr);

    my $byline = File::ByLine->new(
        extended_info   => 1,
        file            => [ glob '~/*.pl ~/*.txt' ],
        processes       => 8,
        skip_unreadable => 1,
    );

    say "File Matches: ",
        join "\n * ", "",
        uniqstr
        sort
        $byline->map( sub ( $, $info ) { /joelle/i ? $info->{filename} : () } );
}

#
# The HARD Solution, trying to do file IO on our own.
#
# I cheated and used Parallel::WorkUnit for parallization, rather than
# rolling parallization from scratch (which would have added at least
# dozens of lines of code!).  Parallel::WorkUnit lets us build an async
# work queue and limit it to 8 processes at a time.  Each file is added
# to the queue, and the Parallel::WorkUnit object allows 8 to run at a
# time.  The EASY solution does this a bit different - it spawns 8 and
# only 8 processes which read 1/8th of every file.  That turns out to
# be quicker for the files in question than the below.
#
# I also applied an optimization - once my name is found, go to the next
# file.  That doesn't happen in easy(), but easy() is STILL faster!
#
# within each queue() sub call, we pass two sub refs - one to read the
# file (executed by the child process) and a second one which is a
# callback once the child finishes execution - it adds any output from
# the first sub.
#
# The first sub returns the filename or nothing,d epending on if the
# string is found.
#
#
sub hard {
    use Parallel::WorkUnit;

    MAIN: {
        my (@files) = glob '~/*.pl ~/*.txt';
        my $wu = Parallel::WorkUnit->new(max_children => 8);

        my @output;
        foreach my $file (@files) {
            if (! -r $file) { next; }

            $wu->queue(
                sub {
                    open my $fh, '<', $file or die($!);
                    while (my $line = <$fh>) {
                        if ($line =~ /joelle/i) {
                            push @output, $file;
                            return $file;
                        }
                    }
                    close $fh;
                    return;
                },
                sub($fn) {
                    if (defined($fn)) {
                        push @output, $fn;
                    }
                }
            );
            $wu->waitall();
        }

        say "File Matches: ", join("\n * ", "", @output);
    }
}

#
# WHICH ONE WOULD YOU RATHER USE?
#


