#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok('Homer') || print "Bail out!\n";
}

diag("Testing Homer $Homer::VERSION, Perl $], $^X");
