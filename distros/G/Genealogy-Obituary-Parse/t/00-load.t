#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Genealogy::Obituary::Parse') || print 'Bail out!';
}

require_ok('Genealogy::Obituary::Parse') || print 'Bail out!';

diag("Testing Genealogy::Obituary::Parse $Genealogy::Obituary::Parse::VERSION, Perl $], $^X");
