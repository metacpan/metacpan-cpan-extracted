#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;
use FindBin '$Bin';

require "$Bin/test_main.pl";
ok(1, "Did not run and exit");

close(STDOUT);
my $output;
open(STDOUT, '>', \$output) or die "Couldn't reopen STDOUT";
run_main('fnord');
is($output, "Hello fnord!\n");
