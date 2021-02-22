#!perl -T

use warnings;
use strict;
use lib './lib';

use Test::Most tests => 2;

BEGIN {
	use_ok('Locale::Places') || print 'Bail out!';
}

require_ok('Locale::Places') || print 'Bail out!';

diag("Testing Locale::Places $Locale::Places::VERSION, Perl $], $^X");
