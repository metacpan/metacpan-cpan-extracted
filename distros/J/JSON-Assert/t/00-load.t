#!/usr/bin/perl

use Test::More tests => 5;

BEGIN {
	use_ok( 'JSON::Assert' );
}

can_ok('JSON::Assert', 'assert_jpath_count');
can_ok('JSON::Assert', 'is_jpath_count');

can_ok('JSON::Assert', 'assert_jpath_value_match');
can_ok('JSON::Assert', 'does_jpath_value_match');

# can_ok('XML::Assert', 'is_different');

diag( "Tested JSON::Assert $JSON::Assert::VERSION, Perl $], $^X, JSON $JSON::VERSION" );
