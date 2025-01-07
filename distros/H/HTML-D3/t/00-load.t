#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('HTML::D3') || print 'Bail out!';
}

require_ok('HTML::D3') || print 'Bail out!';

diag("Testing HTML::D3 $HTML::D3::VERSION, Perl $], $^X");
