use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Function::Return no_check => 1;
use Types::Standard -types;

sub case_invalid :Return(Int) { undef }

ok(!exception { case_invalid() }, 'no error');

done_testing;
