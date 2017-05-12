#!/usr/bin/env perl

use warnings;
use strict;
use Test::More tests => 4;

my $cmd    = "$^X -d:Module::Trace=print t/data/inline.pl 2>&1";
ok(1, $cmd);
my $result = `$cmd`;
like($result, '/\s+Carp.pm\s+/', 'found Carp.pm');
like($result, '/\s+Benchmark.pm\s+/', 'found Benchmark.pm');
like($result, '/\s+Time/HiRes.pm\s+/', 'found Time/HiRes.pm');
