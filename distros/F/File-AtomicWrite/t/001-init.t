#!perl

use warnings;
use strict;

use Test::More tests => 1;
BEGIN { use_ok('File::AtomicWrite') || print "Bail out!\n" }
diag("Testing File::AtomicWrite $File::AtomicWrite::VERSION, Perl $], $^X");
