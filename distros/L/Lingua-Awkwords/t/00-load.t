#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 6;

BEGIN {
    # modules the parser uses
    use_ok('Lingua::Awkwords::ListOf')     || print "Bail out!\n";
    use_ok('Lingua::Awkwords::OneOf')      || print "Bail out!\n";
    use_ok('Lingua::Awkwords::String')     || print "Bail out!\n";
    use_ok('Lingua::Awkwords::Subpattern') || print "Bail out!\n";

    use_ok('Lingua::Awkwords::Parser') || print "Bail out!\n";

    use_ok('Lingua::Awkwords') || print "Bail out!\n";
}

diag("Testing Lingua::Awkwords $Lingua::Awkwords::VERSION, Perl $], $^X");
