package LSU::Test::XS;

use strict;

BEGIN {
    $| = 1;
}

use Test::More;
use List::SomeUtils;

sub run_tests {
    test_xs();
    done_testing();
}

sub test_xs {
    defined $ENV{LIST_MOREUTILS_XS}
        or plan skip_all =>
        "No dedicated test for XS/PP - but can't detect configure time settings at tets runtime";
    is( List::SomeUtils::_XScompiled, 0 + !$ENV{LIST_MOREUTILS_PP},
        "_XScompiled"
    );
}

1;
