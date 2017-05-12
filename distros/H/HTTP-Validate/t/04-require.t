#!perl
# 
# This file tests for proper handling of 'allow' and 'require' rules.

use lib 'lib';

use strict;
use Test::More tests => 19;

use HTTP::Validate qw(:keywords :validators);

# Create some rulesets to use during the following tests:

eval {
     define_ruleset 'A' =>
	{ param => 'foo' },
	{ param => 'bar' },
	{ optional => 'bif' };
	 
     define_ruleset 'B' =>
     	{ optional => 'baz' },
	{ optional => 'buz' };
     
     define_ruleset 'C' =>
	{ param => 'zip' },
	{ param => 'zop' };
     
     define_ruleset 'requireA' =>
	{ require => 'A' };
     
     define_ruleset 'requireBoth' =>
	{ require => 'A' },
	{ require => 'B' };
     
     define_ruleset 'allowBoth' =>
	{ allow => 'A' },
	{ allow => 'B' };
     
     define_ruleset 'requireOne' =>
	{ allow => 'A' },
	{ allow => 'C' },
	{ require_one => ['A', 'C'] };
     
     define_ruleset 'requireAny' =>
	{ allow => 'A' },
	{ allow => 'C' },
	{ require_any => ['A', 'C'] };
     
     define_ruleset 'allowOne' =>
	{ allow => 'A' },
	{ allow => 'C' },
	{ allow_one => ['A', 'C'] };
     
};

ok( !$@, 'test rulesets' ) or diag( "    message was: $@");

my ($result1, $result2, $result3, $result4, $result5, $result6, $result7);
my (@errors1, @errors2, @errors3, @errors4, @errors5, @errors6, @errors7);

# Now check these rulesets against a parameter list.

eval {
    $result1 = check_params('A', {}, { foo => 2 });
    @errors1 = $result1->errors;
    
    $result2 = check_params('requireA', {}, { foo => 2 });
    @errors2 = $result2->errors;
    
    $result3 = check_params('requireA', {}, { bif => 2 });
    @errors3 = $result3->errors;
    
    $result4 = check_params('requireBoth', {}, { foo => 2 });
    @errors4 = $result4->errors;
    
    $result5 = check_params('requireBoth', {}, { bar => 2, baz => 2 });
    @errors5 = $result5->errors;
    
    $result6 = check_params('allowBoth', {}, { foo => 2, baz => 2 });
    @errors6 = $result6->errors;
    
    $result7 = check_params('allowBoth', {}, {});
    @errors7 = $result7->errors;
};

ok( !$@, 'test validations' ) or diag( "    message was: $@");

is( scalar(@errors1), 0, 'basic validation' );
is( $result1->value('foo'), 2, 'basic validation, one param' );
is( scalar(@errors2), 0, 'basic require' );
is( $result2->value('foo'), 2, 'basic require, one param' );
is( scalar(@errors3), 1, 'missing required param' );
is( scalar(@errors4), 0, 'require both, one optional' );
is( $result4->value('foo'), 2, 'require both, one param' );
is( scalar(@errors5), 0, 'require both, one optional 2' );
is( $result5->value('bar'), 2, 'require both, first param' );
is( $result5->value('baz'), 2, 'require both, second param' );
is( scalar(@errors6), 0, 'allow both' );
is( $result6->value('foo'), 2, 'allow both, first param' );
is( $result6->value('baz'), 2, 'allow both, second param' );
is( scalar(@errors7), 0, 'allow both, empty params' );
is( scalar($result7->keys), 0, 'allow both, param result' );

my (@result8);

eval {
    @result8 = list_params('allowBoth');
};

ok( !$@, 'list params' ) or diag( "    message was: $@");

is( join(',', @result8), "foo,bar,bif,baz,buz", 'list params result' );
