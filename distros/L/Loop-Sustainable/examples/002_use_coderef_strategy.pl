#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Loop::Sustainable;
use POSIX qw(strftime);

loop_sustainable {
    my ( $i, $wait_interval ) = @_;
    warn sprintf(
        "[%s] times: %d. interval: %s sec",
        strftime( "%Y-%m-%d %H:%M:%S", localtime ),
        $i, $wait_interval
    );
} (
    sub {
        my ( $i, $time_sum, $rv ) = @_;
        ( $i > 11 ) ? 1 : 0;
    },
    {
        wait_interval           => 0,
        check_strategy_interval => 2,
        strategy                => sub {
            my ( $i, $time_sum, $rv ) = @_;
            return $i;
          }
    }
);
