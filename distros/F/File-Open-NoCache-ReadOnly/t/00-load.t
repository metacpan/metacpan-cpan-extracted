#!perl -wT

use strict;

use Test::Most tests => 2;

BEGIN {
	use_ok('File::Open::NoCache::ReadOnly') || print 'Bail out!';
}

require_ok('File::Open::NoCache::ReadOnly') || print 'Bail out!';

diag( "Testing File::Open::NoCache::ReadOnly $File::Open::NoCache::ReadOnly::VERSION, Perl $], $^X" );
