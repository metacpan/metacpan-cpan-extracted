use Test::More tests => 1;
use strict;
use warnings;
use Devel::DumpTrace::noPPI;

my $z = eval 'use Devel::DumpTrace::PPI; 2';

ok(!defined($z) || $z != 2, 
   "Devel::DumpTrace::PPI not loaded when Devel::DumpTrace::noPPI loaded");
