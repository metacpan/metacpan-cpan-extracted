#!perl -Tw

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Locale::Codes::Country::FR') || print 'Bail out!';
}

require_ok('Locale::Codes::Country::FR') || print 'Bail out!';

diag("Testing Locale::Codes::Country::FR $Locale::Codes::Country::FR::VERSION, Perl $], $^X");
