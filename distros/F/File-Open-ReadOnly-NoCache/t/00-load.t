#!perl -wT

use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('File::Open::ReadOnly::NoCache') || print 'Bail out!';
}

require_ok('File::Open::ReadOnly::NoCache') || print 'Bail out!';

diag( "Testing File::Open::ReadOnly::NoCache $File::Open::ReadOnly::NoCache::VERSION, Perl $], $^X" );
