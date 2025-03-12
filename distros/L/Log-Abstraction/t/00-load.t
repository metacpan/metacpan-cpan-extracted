#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Log::Abstraction') || print 'Bail out!';
}

require_ok('Log::Abstraction') || print 'Bail out!';

diag("Testing Log::Abstraction $Log::Abstraction::VERSION, Perl $], $^X");
