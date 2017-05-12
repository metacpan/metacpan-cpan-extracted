#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Devel::Deprecate') or BAIL_OUT("Well, that sucked.");
}

diag("Testing Devel::Deprecate $Devel::Deprecate::VERSION, Perl $], $^X");
