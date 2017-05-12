#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Iterator::Simple qw(iter);
use Loop::Sustainable;
use POSIX qw(strftime);
use Time::HiRes ();

my $iter = iter( [ 1 .. 10 ] );

loop_sustainable {
    my ( $i, $wait_interval ) = @_;
    Time::HiRes::sleep( rand(1) );
    warn sprintf(
        "[%s] times: %d. wait_interval: %02.2f",
        strftime( "%Y-%m-%d %H:%M:%S", localtime ),
        $i, $wait_interval
    );
    $iter->next;
} (
    sub {
        my ( $i, $time_sum, $rv ) = @_;
        return not defined $rv->[0] ? 1 : 0;
    },
    {
        check_strategy_interval => 2,
        wait_interval           => 0.5,
        strategy                => {
            class => 'ByLoad',
            args  => { load => 0.5 }
        }
    }
);

