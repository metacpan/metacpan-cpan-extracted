use strict;
use warnings;

use lib 't/lib';

BEGIN {
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $ENV{LIST_SOMEUTILS_IMPLEMENTATION} = 'PP';
}

use LSU::Test::Functions;
LSU::Test::Functions->run_tests;

