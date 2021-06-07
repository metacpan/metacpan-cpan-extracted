#!perl -T

use strict;

use Test::Most tests => 1;

BEGIN {
	use_ok('FCGI::Buffer') || print "Bail out!";
}

diag("Testing FCGI::Buffer $FCGI::Buffer::VERSION, Perl $], $^X");
