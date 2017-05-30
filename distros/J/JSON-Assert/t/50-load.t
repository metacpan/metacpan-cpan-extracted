#!/usr/bin/perl

use Test::More tests => 3;

BEGIN {
    use_ok( 'Test::JSON::Assert');
}

can_ok('Test::JSON::Assert', 'is_jpath_count');
can_ok('Test::JSON::Assert', 'does_jpath_value_match');

diag( "Tested Test::JSON::Compare $Test::JSON::Compare::VERSION, Perl $], $^X, JSON $JSON::VERSION" );
