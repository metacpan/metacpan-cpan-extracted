#!perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Math::BigInt::Lite');
    use_ok('Math::BigInt');         # Math::BigInt is required for the tests
};

diag("Testing Math::BigInt::Lite $Math::BigInt::Lite::VERSION");
diag("==> Perl $], $^X");
diag("==> Math::BigInt $Math::BigInt::VERSION");
