# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('Math::BigInt::Named');
    use_ok('Math::BigInt::Named::English');
    use_ok('Math::BigInt::Named::German');
};
