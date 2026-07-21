#!perl
use 5.008003;
use strict;
use warnings;
use Test2::Bundle::Numerical;

use lib 'blib/lib', 'blib/arch';

use_ok('Layout::Flex') || print "Bail out!\n";

done_testing;
