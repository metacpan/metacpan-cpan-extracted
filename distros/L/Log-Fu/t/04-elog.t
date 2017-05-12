#!/usr/bin/perl
use strict;
use warnings;
use Dir::Self;
use lib __DIR__;
use lf_out_test qw(logtester $Output);
use Test::More;
use Log::Fu { level => "warn", target => \&logtester };

my $counter = 0;


elog_debug { "This shouldn't show", $counter = 666 };
is($counter, 0, "Counter remains zero. No evaluating arguments");

elog_warnf { "Have %d items", $counter = 42 };
is($counter, 42, "Argument evaluated with enabled log level");
like($Output, qr/Have 42 items/, "Expected output with format string");



package blargh;
use strict;
use warnings;
use Test::More;
use lf_out_test qw(logtester $Output);
use Log::Fu { level => "warn", target => \&logtester, subs => 1 };

$counter = 0;

log_warn { "This should show" };
like($Output, qr/This should show/, "normal log functions with default names");
log_debugf { "This won't show: %d", $counter = 100 };
is($counter, 0, "Counter not incremented, arguments not evaluated");

log_debugf { die("This will not get evaluated") for (0..1_000) };
ok(1, "Didn't die");

done_testing();