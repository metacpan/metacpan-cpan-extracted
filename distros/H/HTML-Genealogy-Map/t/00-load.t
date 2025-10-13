#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('HTML::Genealogy::Map') || print 'Bail out!';
}

require_ok('HTML::Genealogy::Map') || print 'Bail out!';

diag("Testing HTML::Genealogy::Map $HTML::Genealogy::Map::VERSION, Perl $], $^X");
