#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok('Math::Random::Normal::Leva') || print "Bail out!\n";
}

diag("Testing Math::Random::Normal::Leva $Math::Random::Normal::Leva::VERSION, Perl $], $^X");
