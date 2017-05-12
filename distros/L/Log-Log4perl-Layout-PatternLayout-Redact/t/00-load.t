#!perl -T

use strict;
use warnings;

use Test::More tests => 1;

BEGIN
{
	use_ok( 'Log::Log4perl::Layout::PatternLayout::Redact' ) || print "Bail out!\n";
}

diag( "Log::Log4perl::Layout::PatternLayout::Redact $Log::Log4perl::Layout::PatternLayout::Redact::VERSION, Perl $], $^X" );
