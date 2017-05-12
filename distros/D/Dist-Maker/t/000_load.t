#!perl -w

use strict;
use Test::More tests => 2;

BEGIN {
    use_ok 'Dist::Maker';
    use_ok 'Dist::Maker::Scatter';
}

diag "Testing Dist::Maker/$Dist::Maker::VERSION";
