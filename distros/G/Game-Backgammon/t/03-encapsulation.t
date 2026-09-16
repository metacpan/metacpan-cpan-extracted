#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

# Phase 01's one structural rule: NOTHING outside Board indexes the points
# array. Which way round the board is, is the thing a backgammon engine gets
# wrong, so exactly one class knows and everything else asks it.
#
# This is a grep, and a grep is a blunt test. It is here because the rule it
# defends is not visible in any single place: a second indexer would work
# fine for white and be wrong for black, which is a bug nobody finds for a
# month.

my @offenders;
File::Find::find(sub {
    return unless /\.pm\z/;
    return if $File::Find::name =~ m{Backgammon/Board\.pm\z};
    open my $fh, '<', $_ or return;
    my $n = 0;
    while (my $line = <$fh>) {
        $n++;
        next if $line =~ /\A\s*#/;
        # both the old hash form and the accessor: reaching the array at
        # all is the thing forbidden, however it is spelled
        push @offenders, "$File::Find::name:$n: $line"
            if $line =~ /\{points\}\s*(?:\[|->\[)/
            || $line =~ /->points\s*->\s*\[/;
    }
    close $fh;
}, 'lib');

is(scalar @offenders, 0, 'only Board indexes the points array')
    or diag("  $_") for @offenders;

# and the accessor everything is supposed to use exists and is the only
# thing that knows the direction
require Game::Backgammon::Board;
can_ok('Game::Backgammon::Board', qw(index_for point_for mine_on theirs_on));

done_testing();
