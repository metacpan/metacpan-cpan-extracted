use Test::More tests => 1;
use strict;
use warnings;

BEGIN {
  no warnings 'once';
  $Devel::DumpTrace::NO_PPI = 1;
}

my $z = eval 'use Devel::DumpTrace::PPI; 2';

ok(!defined($z) || $z != 2,
   "Devel::DumpTrace::PPI not loaded when \$NO_PPI set");

