package Method::Signatures::PP::Compile;

use strict;
use warnings;
use Module::Compile -base;
use Method::Signatures::PP ();

sub pmc_compile { Method::Signatures::PP::mangle($_[1]) }

1;
