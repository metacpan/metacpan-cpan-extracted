#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Encode::Wide') || print 'Bail out!';
}

require_ok('Encode::Wide') || print 'Bail out!';

diag("Testing Encode::Wide $Encode::Wide::VERSION, Perl $], $^X");
