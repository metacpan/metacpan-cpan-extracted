use strict;
use warnings;

use lib 't/lib';

BEGIN {
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $ENV{LIST_SOMEUTILS_IMPLEMENTATION} = 'PP';
}

use Test::More 0.96;

use LSU::Test::Import;
LSU::Test::Import->run_tests;

