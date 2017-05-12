#!perl

use lib 'lib';

use strict;
use Test::More tests => 12;

use HTTP::Validate qw(:keywords :validators);

sub test_validator { };
sub test_validator2 { };

# Start by testing that we can create new HTTP::Validate objects, and that
# 'define_ruleset', 'validation_settings' and 'validate_params' work properly both as
# method calls and as function calls.

my $TestValidation = new_ok( 'HTTP::Validate' => [], 'new validation' );

my $PermissiveValidation = new_ok( 'HTTP::Validate' => [ allow_unrecognized => 1 ], 'permissive validation' );

subtest 'basic calls' => sub {
    
    eval {
	my $test = HTTP::Validate->new(foo => 'bar');
    };
    
    ok( $@, 'bad validation setting' );
    
    eval {
	define_ruleset 'foo' => 
	    { param => 'bar' };
    };
    
    ok( !$@, 'basic ruleset definition' ) or diag("    message was: $@");
    
    eval {
	$TestValidation->define_ruleset('foo' =>
	    { param => 'bar' });
	
	$PermissiveValidation->define_ruleset('foo' =>
	    { param => 'bar' });
	
	# Note: the same ruleset name can be used with two different validation
	# objects, because each has its own namespace.
    };
    
    ok( !$@, 'object ruleset definition' ) or diag("    message was: $@");
    
    eval {
	validation_settings(allow_unrecognized => 1);
    };
    
    ok( !$@, 'module validation settings' ) or diag("    message was $@");
    
    eval {
	$PermissiveValidation->validation_settings(allow_unrecognized => 1);
    };
    
    ok( !$@, 'object validation settings' ) or diag("    message was: $@");
    
    # Test that repeated ruleset names generate the proper error
    
    eval {
	define_ruleset 'foo' => 
	    { param => 'bar' };
    };
    
    cmp_ok( $@, '=~', "^ruleset 'foo' was already defined at line 30", 'repeated ruleset name' );
    
    eval {
	$TestValidation->define_ruleset('foo' =>
	    { param => 'baz' });
    };
    
    cmp_ok( $@, '=~', "^ruleset 'foo' was already defined at line 37", 'object repeated ruleset name' );
};


# Test that erroneous calls to 'define_ruleset' are caught

subtest 'define_ruleset bad' => sub {
    
    eval {
	define_ruleset { param => 'bar' };
    };
    
    ok( $@, 'ruleset name required' );
    
    eval {
	define_ruleset 23 => { param => 'bar' };
    };
    
    ok( !$@, 'numeric ruleset name' ) or diag("    message was: $@");
    
    eval {
	define_ruleset '' => { param => 'bar' };
    };
    
    ok( $@, 'no empty ruleset names' );
    
    eval {
	define_ruleset 'non-hash reference' =>
	    &HTTP::Validate::define_ruleset;
    };
    
    ok( $@, 'non-hash reference' );
    
    eval {
	define_ruleset 'bad rule type' => 
	{ 'fitzwilliam' => 1 };
    };
    
    ok( $@, 'bad rule type' );
};
    

# Test that all of the documented parameter rule types are accepted

subtest 'rule types' => sub {
    
    eval {
	define_ruleset 'parameter rule types' =>
	    { param => 'bar' },
	    { optional => 'baz' },
	    { mandatory => 'biff' },
	    { ignore => 'buff' },
	    { together => ['bar', 'baz'] },
	    { at_most_one => ['baz', 'biff'] };
    };
    
    ok( !$@, 'parameter rule types' ) or diag("    message was: $@");
    
    # Test that erroneous parameter rule specifiers are caught
    
    eval {
	define_ruleset 'ambiguous rule type' => 
	    { 'param' => 'foo', 'optional' => 'bar' };
    };
    
    ok( $@, 'ambiguous rule type' );
    
    eval {
	define_ruleset 'non-string parameter' => 
	    { param => ['abc'] };
    };
    
    ok( $@, 'non-string parameter' );
};


# Test that one or more validators and an error hash are accepted, but that
# erroneous combinations are not.

subtest 'validators' => sub {
    
    eval {
	define_ruleset 'validators and options hashes' =>
	    { param => 'bar', valid => \&test_validator },
	    { param => 'baz', valid => \&test_validator, errmsg => 'aha' },
	    { param => 'foo', valid => [\&test_validator, \&test_validator2] },
	    { param => 'fuz', valid => [\&test_validator, \&test_validator2], 
	      errmsg => 'aha' };
    };
    
    ok( !$@, 'validators and options hashes' ) or diag("    message was: $@");
    
    eval {
	define_ruleset 'bad validator' =>
	    { param => 'bar', valid => 'foo' };
    };
    
    ok( $@, 'bad validator' );
    
    eval {
	define_ruleset 'bad validator 2' =>
	    { param => 'bar', valid => { 'baz' => 1 }, errmsg => 'b' };
    };
    
    ok( $@, 'bad validator 2' );
};


# Test that all of the documented options (and only those) are allowed in
# rule hashes.

subtest 'builtin names' => sub {
    
    eval {
	define_ruleset 'bad option name' =>
	    { param => 'bar', foo => 'bar' };
    };
    
    ok( $@, 'bad option name' );
    
    eval {
	define_ruleset 'good option names' =>
	    { param => 'bar', errmsg => 'baz', warn => 'biff', alias => 'boo', 
	      split => 'blam', list => 'blip', multiple => 'blap',
	      bad_value => 'buzz', key => 'bzzzip', default => 'bobble' };
    };
    
    ok( !$@, 'good option names' ) or diag("    message was: $@");
    
    # Test that all of the documented validators are accepted.
    
    eval {
	define_ruleset 'built-in validators' =>
	    { param => 'int', valid => INT_VALUE },
	    { param => 'pos', valid => POS_VALUE },
	    { param => 'posz', valid => POS_ZERO_VALUE },
	    { param => 'decimal', valid => DECI_VALUE },
	    { param => 'enum', valid => ENUM_VALUE('abc') },
	    { param => 'bool', valid => BOOLEAN_VALUE },
	    { param => 'flag', valid => FLAG_VALUE },
	    { param => 'string', valid => MATCH_VALUE(qr{^[ a-zA-Z]+$}) },
	    { param => 'any', valid => ANY_VALUE };
    };
    
    ok( !$@, 'built-in validators' ) or diag("    message was: $@");
};


# Test that the built-in validators accept good arguments and reject bad ones.

subtest 'validator arguments' => sub {
    
    eval {
	define_ruleset 'int validator bad' =>
	    { param => 'bar', valid => INT_VALUE('a', 'b') };
    };
    
    ok( $@, 'int validator bad' );
    
    eval {
	define_ruleset 'int validator good' =>
	    { param => 'pos', valid => INT_VALUE(1) },
	    { param => 'bar', valid => INT_VALUE(2, 3) },
	    { param => 'baz', valid => INT_VALUE(-1, 5) },
	    { param => 'buz', valid => INT_VALUE(0, 0) },
	    { param => 'neg', valid => INT_VALUE(-5,-3) };
    };
    
    ok( !$@, 'int validator good' ) or diag("    message was: $@");
    
    eval {
	define_ruleset 'decimal validator bad' =>
	    { param => 'bar', valid => DECI_VALUE('abc') };
    };
    
    ok ( $@, 'decimal validator bad' );
    
    eval {
	define_ruleset 'decimal validator good' =>
	    { param => 'bar', valid => DECI_VALUE(0,10) },
	    { param => 'baz', valid => DECI_VALUE(-10,10) },
	    { param => 'buz', valid => DECI_VALUE(5.0, 15.5) },
	    { param => 'exp', valid => DECI_VALUE(5.2e-10, 5.3e15) };
    };
    
    ok( !$@, 'decimal validator good' ) or diag("    message was: $@");
    
    eval {
	define_ruleset 'enum validator bad' =>
	    { param => 'bar', valid => ENUM_VALUE };
    };
    
    ok( $@, 'enum validator bad' );
    
    eval {
	define_ruleset 'enum validator good' => 
	    { param => 'bar', valid => ENUM_VALUE('abc', 'DEF', 3) };
    };
    
    ok( !$@, 'enum validator good' ) or diag("    message was: $@");
    
    eval { 
	define_ruleset 'match validator bad' =>
	    { param => 'bar', valid => MATCH_VALUE };
    };
    
    ok( $@, 'match validator bad' );

    eval {
	define_ruleset 'match validator bad 2' =>
	    { param => 'bar', valid => MATCH_VALUE([2]) };
    };
    
    ok( $@, 'match validator bad 2' );
    
    eval {
	define_ruleset 'match validator good' =>
	    { param => 'bar', valid => MATCH_VALUE('^abc[de]+$') },
	    { param => 'baz', valid => MATCH_VALUE(qr{^abc[de]+$}) };
    };
    
    ok( !$@, 'match validator good' ) or diag("    message was: $@");
};


# Generate some test rulesets for the next set of tests

eval {
    define_ruleset 'test1' => 
	{ param => 'bar' };
    
    define_ruleset 'test2' =>
	{ param => 'baz' };
};

ok( !$@, 'test rulesets' ) or diag("    message was; $@" );

# Test that good calls to combining rules are accepted and bad ones are
# caught.

subtest 'combining rules' => sub {
    
    eval {
	define_ruleset 'allow rule bad' =>
	    { 'allow' => undef };
    };
    
    ok( $@, 'allow rule bad');
    
    eval {
	define_ruleset 'allow rule bad 2' =>
	    { 'allow' => { errmsg => 'foo' }, errmsg => 'bar' };
    };
    
    ok( $@, 'allow rule bad 2');
    
    eval {
	define_ruleset 'allow rule bad name' =>
	    { allow => 'no rule at all' };
    };
    
    ok( $@, 'allow rule bad name');
    
    eval {
	define_ruleset 'allow rule good' =>
	    { allow => 'test1' },
	    { allow => 'test2', errmsg => 'foo' },
	};
    
    ok( !$@, 'allow rule good' ) or diag("    message was: $@");
    
    eval {
	define_ruleset 'require rule good' =>
	    { require => 'test1' },
	    { require => 'test2', errmsg => 'foo' };
    };
    
    ok( !$@, 'require rule good' ) or diag("    message was: $@");
    
    eval {
	define_ruleset 'other rules' =>
	    { allow => 'test1' },
	    { allow => 'test2' },
	    { allow_one => ['test1', 'test2'] },
	    { require_one => ['test1', 'test2'] },
	    { require_any => ['test1', 'test2'] };
    };
    
    ok( !$@, 'other rules' ) or diag("    message was: $@");
};
    

# Check that good content_type rules are accepted and bad ones are caught.

subtest 'content_type rules' => sub {
    
    eval {
	define_ruleset 'content_type bad' =>
	    { content_type => 'foo', valid => ['flip'] };
    };
    
    ok( $@, 'content_type bad');
    
    eval {
	define_ruleset 'content_type good' =>
	    { content_type => 'ctype', valid => ['html', 'json', 'foo=application/foobar'] };
    };
    
    ok( !$@, 'content_type good' ) or diag("    message was: $@");
};


subtest 'ruleset_defined' => sub {
    
    ok( ruleset_defined('content_type good'), "found ruleset 'content_type good'" );
    ok( ! ruleset_defined('not a ruleset'), "didn't find ruleset 'not a ruleset'" );
};
