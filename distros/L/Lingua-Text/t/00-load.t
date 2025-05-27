#!perl -T

use strict;
use warnings;

use Test::Most tests => 2;

BEGIN {
	use_ok('Lingua::Text') || print 'Bail out!';
}

require_ok('Lingua::Text') || print 'Bail out!';

diag("Testing Lingua::Text $Lingua::Text::VERSION, Perl $], $^X");
