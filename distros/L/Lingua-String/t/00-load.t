#!perl -T

use strict;
use warnings;

use Test::Most tests => 2;

BEGIN {
	use_ok('Lingua::String') || print 'Bail out!';
}

require_ok('Lingua::String') || print 'Bail out!';

diag("Testing Lingua::String $Lingua::String::VERSION, Perl $], $^X");
