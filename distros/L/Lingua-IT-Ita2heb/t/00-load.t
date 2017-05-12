#!perl -T
## no critic

use Test::More tests => 1;

BEGIN {
    use_ok('Lingua::IT::Ita2heb') || print "Bail out!
";
}

diag("Testing Lingua::IT::Ita2heb $Lingua::IT::Ita2heb::VERSION, Perl $], $^X"
);
