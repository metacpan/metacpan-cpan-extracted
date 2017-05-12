#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Math::Prime::TiedArray');
}

diag(
"Testing Math::Prime::TiedArray $Math::Prime::TiedArray::VERSION, Perl $], $^X"
);
