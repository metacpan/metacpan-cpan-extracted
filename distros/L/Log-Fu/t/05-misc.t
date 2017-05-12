#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

my $counter = 0;

sub log_warn {
    $counter = 42;
}

use Log::Fu { level => 'crit', function_prefix => 'test_' };
test_log_warn('hi');
log_warn('bye');

is($counter, 42, "Our function was not clobbered");

done_testing();