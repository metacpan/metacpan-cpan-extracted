#!/usr/bin/perl

use warnings;
use strict;

eval "use Test::Pod 1.00";

my $no_tp = $@ ? 1 : undef; # Cornholio exception

# Test::Pod automatically plans, so if we /don't/ have it, we have
# to plan one test... that will never be run. Great.
$no_tp ? eval "use Test::More tests => 1" : eval "use Test::More";

SKIP: {
	Test::More::skip("Test::Pod 1.00 required for testing POD", 1) if $no_tp;

	all_pod_files_ok();
}