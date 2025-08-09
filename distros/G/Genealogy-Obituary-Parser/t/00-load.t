#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Genealogy::Obituary::Parser') || print 'Bail out!';
}

require_ok('Genealogy::Obituary::Parser') || print 'Bail out!';

diag("Testing Genealogy::Obituary::Parser $Genealogy::Obituary::Parser::VERSION, Perl $], $^X");
