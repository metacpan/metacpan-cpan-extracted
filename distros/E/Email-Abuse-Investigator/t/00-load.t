#!perl -w

use warnings;
use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('Email::Abuse::Investigator') || print 'Bail out!';
}

require_ok('Email::Abuse::Investigator') || print 'Bail out!';

diag("Testing Email::Abuse::Investigator $Email::Abuse::Investigator::VERSION, Perl $], $^X");
