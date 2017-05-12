#!perl

use lib 'lib';

use strict;
use Test::More tests => 4;

use HTTP::Validate qw(:keywords :validators);

# Create some rulesets to use during the following tests:

# First test numeric parameter values

subtest 'numeric validators' => sub {
    
    my ($result1, $result2, $result3, $result4);
    
    eval {
	define_ruleset 'integer' =>
	    { param => 'int1', valid => INT_VALUE },
	    { param => 'int2', valid => INT_VALUE },
	    { param => 'int3', valid => INT_VALUE },
	    { param => 'int4', valid => INT_VALUE },
	    { param => 'int5', valid => INT_VALUE },
	    { param => 'int6', valid => INT_VALUE };
	
	define_ruleset 'decimal' =>
	    { param => 'dec1', valid => DECI_VALUE },
	    { param => 'dec2', valid => DECI_VALUE },
	    { param => 'dec3', valid => DECI_VALUE },
	    { param => 'dec4', valid => DECI_VALUE },
	    { param => 'dec5', valid => DECI_VALUE },
	    { param => 'dec6', valid => DECI_VALUE },
	    { param => 'dec7', valid => DECI_VALUE };
	
	my $test_int = INT_VALUE(-4, 5);
	
	define_ruleset 'int range' =>
	    { param => 'int01', valid => $test_int },
	    { param => 'int02', valid => $test_int },
	    { param => 'int03', valid => $test_int },
	    { param => 'int04', valid => $test_int },
	    { param => 'int05', valid => $test_int },
	    { param => 'int06', valid => POS_VALUE },
	    { param => 'int07', valid => POS_VALUE },
	    { param => 'int08', valid => POS_VALUE },
	    { param => 'int09', valid => POS_ZERO_VALUE },
	    { param => 'int10', valid => POS_ZERO_VALUE },
	    { param => 'int11', valid => POS_ZERO_VALUE };
	
	my $test_dec = DECI_VALUE(-0.01, 15.4);
	my $test_dec2 = DECI_VALUE(2, 5);
	
	define_ruleset 'dec range' => 
	    { param => 'dec01', valid => $test_dec },
	    { param => 'dec02', valid => $test_dec },
	    { param => 'dec03', valid => $test_dec },
	    { param => 'dec04', valid => $test_dec },
	    { param => 'dec05', valid => $test_dec },
	    { param => 'dec06', valid => $test_dec2 },
	    { param => 'dec07', valid => $test_dec2 },
	    { param => 'dec08', valid => $test_dec2 };
	
	$result1 = check_params('integer', {}, [int1 => 23, int2 => -23, int3 => 23.5, 
						int4 => 'abc', int5 => '', int6 => '0']);
	$result2 = check_params('decimal', {}, [dec1 => 23, dec2 => -23, dec3 => 23.5,
						dec4 => 'abc', dec5 => '', dec6 => '0', dec7 => '0.23e3']);
	$result3 = check_params('int range', {}, [int01 => 0, int02 => 5, int03 => -4, int04 => 6, 
						  int05 => -5, int06 => 0, int07 => 1, int08 => -1,
						  int09 => 0, int10 => 1, int11 => -1]);
	$result4 = check_params('dec range', {}, [dec01 => 0, dec02 => 15.4, dec03 => -0.01,
						  dec04 => 15.400001, dec05 => -0.02, dec06 => '0.3e1',
						  dec07 => '0.1e1', dec08 => 0]);
    };
    
    ok( !$@, 'check rulesets' ) or diag("    message was: $@");
    
    cmp_ok($result1->value('int1'), '==', 23.0, 'int1');
    cmp_ok($result1->value('int2'), '==', -23.0, 'int2');
    is($result1->value('int3'), undef, 'int3');
    is($result1->value('int4'), undef, 'int4');
    is($result1->value('int5'), undef, 'int5');
    cmp_ok($result1->value('int6'), 'eq', '0', 'int6');
    
    is_deeply([sort $result1->error_keys], ['int3', 'int4'], 'int params 2');
    
    cmp_ok($result2->value('dec1'), '==', 23, 'dec1');
    cmp_ok($result2->value('dec2'), '==', -23, 'dec2');
    cmp_ok($result2->value('dec3'), '==', 23.5, 'dec3');
    is($result2->value('dec4'), undef, 'dec4');
    is($result2->value('dec5'), undef, 'dec5');
    cmp_ok($result2->value('dec6'), '==', 0, 'dec6');
    cmp_ok($result2->value('dec7'), '==', 2.3e2, 'dec7');
    is_deeply([sort $result2->error_keys], ['dec4'], 'dec params 2');
    
    is_deeply([sort $result3->error_keys], ['int04', 'int05', 'int06', 'int08', 'int11'], 'int range 2');
    is_deeply([sort $result4->error_keys], ['dec04', 'dec05', 'dec07', 'dec08'], 'dec range 2');
};


subtest 'enum validators' => sub {
    
    my ($r1, $r2);
    
    eval {

	my $test_enum = ENUM_VALUE('abc', 'DEF', 'ghi');
	
	define_ruleset 'enum test' =>
	    { param => 'enum1', valid => $test_enum },
	    { param => 'enum2', valid => $test_enum },
	    { param => 'enum3', valid => $test_enum };
	
	$r1 = check_params('enum test', {}, [enum1 => 'abc', enum2 => 'Abc', enum3 => 'foo']);
	$r2 = check_params('enum test', {}, [enum1 => 'def']);
    };
    
    ok( !$@, 'define and check rulesets' ) or diag( "    message was: $@" );
    
    is_deeply( [sort $r1->error_keys], ['enum3'], 'proper enum errors' );
    
    is( $r1->value('enum2'), 'abc', "proper value for 'enum2'" );
    is( $r2->value('enum1'), 'DEF', "proper value for 'enum1'" );
};


subtest 'match validators' => sub {

    my ($r1, $r2, $r3);
    
    eval {

	my $test_match1 = MATCH_VALUE('ab*');
	my $test_match2 = MATCH_VALUE(qr{ab*});
	
	define_ruleset 'match test' =>
	    { param => 'match1', valid => $test_match1 },
	    { param => 'match2', valid => $test_match2 },
	    { param => 'match3', valid => $test_match1 },
	    { param => 'match4', valid => $test_match2 },
	    { param => 'match5', valid => $test_match1 },
	    { param => 'match6', valid => $test_match2 };
	
	define_ruleset 'match 2' =>
	    { param => 'foo', valid => MATCH_VALUE('^abc') },
	    { param => 'bar', valid => MATCH_VALUE(qr{^abc}i) };
	
	$r1 = check_params('match test', {}, [match1 => 'Abb', match2 => 'Abb',
					      match3 => 'abc', match4 => 'abc',
					      match5 => '', match6 => '']);
	
	$r2 = check_params('match 2', {}, { foo => 'abcd' });
	$r3 = check_params('match 2', {}, { bar => 'ABCD' });
    };
    
    ok( !$@, 'define and check rulesets' ) or diag("    message was: $@");
    
    is_deeply([sort $r1->error_keys], ['match2', 'match3'], 'proper match errors');
    ok( ! $r2->passed, "match failed with 'foo'" );
    ok( $r3->passed, "match passed with 'bar'" );
};


# Now define a custom validator and make sure we can return 'value' and 'warning' fields.  The
# 'error' field has already been tested with the built-in validators.  Also check to make sure
# that the $context argument is properly passed.

subtest 'custom validator' => sub {
    
    my ($r1, $r2, $r3);
    
    eval {
	
	my $v1 = sub { 
	    my ($value, $context) = @_;
	    
	    return { value => { data => uc $value } } if defined $context->{valid} && $value eq $context->{valid};
	    return { warn => "the value of {param} is strange (was {value})" };
	};
	
	define_ruleset('custom' => 
	    { optional => 'foo', valid => $v1 });
	
	$r1 = check_params('custom', {}, { foo => 'abc' });
	$r2 = check_params('custom', { valid => 'abc' }, { foo => 'abc' });
    };
    
    ok( $r1->passed, 'r1 passed' );
    ok( $r2->passed, 'r2 passed' );
    
    my @w1 = $r1->warnings;
    my @w2 = $r2->warnings;
    
    cmp_ok( @w1, '==', 1, 'r1 had one warning' );
    cmp_ok( @w2, '==', 0, 'r2 had no warnings' );
    
    my $v1 = $r1->value('foo');
    my $v2 = $r2->value('foo');
    
    is( $v1, 'abc', 'r1 had proper value' );
    ok( ref $v2 eq 'HASH' && $v2->{data} eq 'ABC', 'r2 had proper value' );
};
