#!/usr/bin/perl

use Test::Inter;
my $t = new Test::Inter;

eval "use Test::Pod::Coverage 1.00";
$t->feature('Test::Pod::Coverage',1)  unless ($@);
$t->feature('DoPOD',1)                unless ($ENV{'TI_SKIPPOD'});

$t->skip_all('','Test::Pod::Coverage','DoPOD');
all_pod_coverage_ok();
