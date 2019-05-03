### loads Devel::DumpTrace with an additional flag 
### to inhibit using Devel::DumpTrace::PPI

package Devel::DumpTrace::noPPI;

use strict;
use warnings;
our $VERSION = '0.29';

BEGIN {
  $Devel::DumpTrace::NO_PPI = 1;
}
use Devel::DumpTrace;

sub Devel::DumpTrace::noPPI::import {
  goto &Devel::DumpTrace::import;
}

1;
