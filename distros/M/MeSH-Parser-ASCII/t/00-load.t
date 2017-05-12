#!perl

use Test::More tests => 1;

BEGIN {
	use_ok('MeSH::Parser::ASCII') || print "Bail out!";
}

diag("Testing MeSH::Parser::ASCII $MeSH::Parser::ASCII::VERSION, Perl $], $^X");
