#!perl

use lib 'lib';

use strict;
use Test::More tests => 14;

use HTTP::Validate qw(:keywords :validators);

sub test_validator { };

# Test that we can create new HTTP::Validate objects, both permissive and not.

my $TestValidation = new_ok( 'HTTP::Validate' => [], 'new validation' );
my $TestPermissive = new_ok( 'HTTP::Validate' => [ allow_unrecognized => 1 ], 
			     'new validation permissive' );
my $TestIgnore = new_ok( 'HTTP::Validate' => [ ignore_unrecognized => 1 ],
			'new validation ignore' );

# Create some rulesets to use during the following tests:

eval {
    define_ruleset 'simple params' => 
	{ param => 'foo' },
	{ param => 'bar' };
     
    $TestValidation->define_ruleset('simple params' =>
	{ param => 'foo' },
	{ param => 'bar' });
    
    $TestPermissive->define_ruleset('simple params' =>
	{ param => 'foo' },
	{ param => 'bar' });
    
    define_ruleset 'multiple params' =>
	{ optional => 'foo', multiple => 1 },
	{ optional => 'bar', multiple => 1 };
    
    define_ruleset 'split params' =>
	{ optional => 'foo', split => ',' },
	{ optional => 'bar', split => qr/ : / };
    
    define_ruleset 'empty params' => 
	{ optional => 'foo', valid => FLAG_VALUE },
	{ optional => 'baz', valid => ANY_VALUE };
    
    define_ruleset 'default value' =>
	{ optional => 'bar', valid => INT_VALUE, default => 74 };
    
    define_ruleset 'mandatory param' =>
	{ mandatory => 'foo', valid => ANY_VALUE },
	{ mandatory => 'bar', valid => ANY_VALUE };
     
    define_ruleset 'list params' =>
	{ optional => 'foo', list => ',', valid => POS_VALUE, bad_value => -1 },
	{ optional => 'bar', list => ',', valid => POS_VALUE, bad_value => -1 },
	{ optional => 'baz', list => ',', valid => POS_VALUE, bad_value => 'ERROR' };
};

ok( !$@, 'test rulesets' ) or diag( "    message was: $@" );

my %simple_params = ( foo => 1, bar => 2 );
my %missing_param = ( foo => 1, bar => '' );
my %extra_param = ( foo => 1, bar => 2, baz => 3 );

# Do some simple validations, and test that the 'unrecognized parameter'
# mechanism works properly.

subtest 'basic checks' => sub {

    my ($r1, $r2, $r3, $r4, $r5, $r5a);
    
    eval {
	$r1 = check_params('simple params', {}, \%simple_params);
	$r2 = check_params('simple params', {}, \%missing_param);
	$r3 = check_params('simple params', {}, \%extra_param);
	$r4 = $TestValidation->check_params('simple params', {}, \%extra_param);
	$r5 = $TestPermissive->check_params('simple params', {}, \%extra_param);
	$r5a = check_params('mandatory param', {}, \%missing_param);
    };
    
    ok( !$@, 'simple params validation' ) || diag( "    message was: $@" );
    
    is( $r1->value('foo'), '1', 'simple params 1' );
    is( $r1->value('bar'), '2', 'simple params 2' );
    is( $r1->errors, 0, 'simple params 3');
    is( $r1->warnings, 0, 'simple params 4');
    ok( $r1->specified('foo'), 'simple params 5');
    ok( ! $r1->specified('biff'), 'simple params 6');
    
    is( $r2->value('foo'), '1', 'missing param 1' );
    is( $r2->value('bar'), undef, 'missing param 2' );
    is( $r2->errors, 0, 'missing param 3');
    is( $r2->warnings, 0, 'missing param 4');
    ok( $r2->passed, 'missing param 5');
    ok( $r2->specified('foo'), 'missing param 6');
    ok( ! $r2->specified('bar'), 'missing param 7');
    
    is( $r3->errors('baz'), 1, 'extra param error 1' );
    is( $r3->errors, 1, 'extra param error 1a' );
    my ($errmsg) = $r3->errors('baz');
    is( $errmsg, "unknown parameter 'baz'", 'extra param error 2' );
    is( $r3->warnings, 0, 'extra param error 3');
    ok( ! $r3->passed, 'extra param not passed');
    
    is( $r4->errors('baz'), 1, 'extra param object error 1' );
    is( $r4->errors, 1, 'extra param object error 1a' );
    ($errmsg) = $r4->errors('baz');
    is( $errmsg, "unknown parameter 'baz'", 'extra param object error 2' );
    is( $r4->warnings, 0, 'extra param object error 3');
    
    is( $r5->errors('baz'), 0, 'extra param permissive 1' );
    is( $r5->errors, 0, 'extra param permissive 1a');
    ($errmsg) = $r5->errors('baz');
    is( $errmsg, undef, 'extra param permissive 2' );
    is( $r5->warnings, 1, 'extra param permissive 3');
    is( $r5->warnings('baz'), 1, 'extra param permissive 4');
    my ($warnmsg) = $r5->warnings('baz');
    is( $warnmsg, "unknown parameter 'baz'", 'extra param permissive 5');
    
    # Test that mandatory parameters work properly.
    
    is( $r5a->errors('bar'), 1, 'mandatory param error 1' );
    is( $r5a->errors, 1, 'mandatory param error 2' );
    ($errmsg) = $r5a->errors('bar');
    is( $errmsg, "you must specify a value for 'bar'", 'mandatory param errmsg');
};


# Test that combinations of hashrefs and other parameters work properly, and
# that multiple parameters are handled properly.

subtest 'combination parameters' => sub {

    my ($r6, $r7, $r8, $errmsg, $warnmsg);
    
    eval {
	$r6 = check_params('simple params', {}, [ \%missing_param, 'bar' => 2 ]);
	$r7 = check_params('simple params', {}, [ \%simple_params, bar => 3 ]);
	$r8 = check_params('multiple params', {}, [ \%simple_params, bar => 3 ]);
    };
    
    ok( !$@, 'combo params validation' );
    diag( "    message was: $@" ) if $@;
    
    is( $r6->value('foo'), '1', 'combo params 1' );
    is( $r6->value('bar'), '2', 'combo params 2' );
    is( $r6->errors, 0, 'combo params 3');
    is( $r6->warnings, 0, 'combo params 4');
    
    is( $r7->value('foo'), '1', 'multiple params 1' );
    is( $r7->errors, 1, 'multiple params 3');
    ($errmsg) = $r7->errors;
    cmp_ok( $errmsg, '=~', "^you may only specify one value for '?bar'?", 'multiple params 4');
    is( $r7->warnings, 0, 'multiple params 5');
    
    is_deeply( $r8->value('foo'), [1], 'multiple good 1' );
    is_deeply( $r8->value('bar'), [2, 3], 'multiple good 2' );
    is( $r8->errors, 0, 'multiple good 3');
    is( $r8->warnings, 0, 'multiple good 4');
};


# Test that parameter splitting works properly

subtest 'paramter splitting' => sub {
    
    my ($r9, $r10, $r11, $r11a, $r11b);
    
    eval {
	$r9 = check_params('split params', {}, [ foo => 'abc, , def,ghi  ,, jkl', bar => '' ]);
	$r10 = check_params('split params', {}, [ bar => 'abc : def  :  ghi:jkl' ]);
	$r11 = check_params('split params', {}, [ foo => ',, ,' ]);
	$r11a = check_params('list params', {}, [ foo => '1,  2,, 3,a,b', bar => 'a', baz => '' ]);
	$r11b = check_params('list params', {}, [ baz => 'abc, def' ]);
    };
    
    ok( !$@, 'split params validation' );
    diag( "    message was: $@" ) if $@;
    
    is_deeply( $r9->value('foo'), ['abc', 'def', 'ghi', 'jkl'], 'split good 1' );
    is( $r9->value('bar'), undef, 'split good 2');
    is( $r9->errors, 0, 'split good 3') or diag explain $r9->errors;
    is( $r9->warnings, 0, 'split good 4') or diag explain $r9->warnings;
    my @keys = $r9->keys();
    is_deeply( \@keys, ['foo'], 'split keys 1' );
    
    is_deeply( $r10->value('bar'), ['abc', 'def ', ' ghi:jkl'], 'split good 1a' ) or diag explain $r10->value('bar');
    is( $r10->errors, 0, 'split good 2a') or diag explain $r10->errors;
    is( $r10->warnings, 0, 'split good 3a') or diag explain $r10->warnings;
    
    is( $r11->value('foo'), undef, 'split good 1b');
    is( $r11->errors, 0, 'split good 2b') or diag explain $r11->errors;
    is( $r11->warnings, 0, 'split good 3b') or diag explain $r11->warnings;
    @keys = $r11->keys();
    is( @keys, 0, 'split keys 2' );
    
    is( $r11a->warnings, 3, 'list bad value warnings' );
    is_deeply( [sort $r11a->warning_keys], ['bar', 'foo'], 'warning keys' );
    is( $r11a->errors, 0, 'list bad value no errors' ) or diag explain $r11a->errors;
    is_deeply( $r11a->value('foo'), [1, 2, 3], 'list values some good' );
    is_deeply( $r11a->value('bar'), [-1], 'list values all bad' );
    is( $r11a->value('baz'), undef, 'list values none' );
    @keys = sort $r11a->keys();
    is_deeply( \@keys, ['bar', 'foo'], 'list keys 1' );
    
    is( $r11b->warnings, 2, 'list bad value warnings 2' );
    is( $r11b->errors, 1, 'list bad value error count' );
    my ($errmsg) = $r11b->errors;
    cmp_ok( $errmsg, '=~', qr{ valid .* 'baz' .* 'abc' .* 'def' }xs, 'list bad value errmsg' );
    ok( $r11b->specified('baz'), 'list bad value specified' );
    ok( ! defined $r11b->value('baz'), 'list bad value undef' );
};


# Test that empty params work properly

subtest 'empty params' => sub {
    
    my ($result12, $result13, $result14);
    
    my %undef_params = ( foo => undef, baz => undef );
    my %empty_params = ( foo => '', baz => '' );
    my %no_flag_params = ( baz => 'abc' );
    
    eval {
	$result12 = check_params('empty params', {}, \%undef_params);
	$result13 = check_params('empty params', {}, \%empty_params);
	$result14 = check_params('empty params', {}, \%no_flag_params);
    };
    
    ok( !$@, 'empty params validation' ) || diag("    message was: $@" );
    
    is( $result12->value('foo'), 1, 'flag good 1' );
    is( $result12->value('baz'), undef, 'any good 1' );
    
    is( $result13->value('foo'), 1, 'flag good 2' );
    is( $result13->value('baz'), undef, 'any good 2' );
    
    is( $result14->value('foo'), undef, 'flag good 3' );
    is( $result14->value('baz'), 'abc', 'any good 3' );
};


# Test that 'validation_settings' works properly

subtest 'validation_settings' => sub {
    
    my ($r15, $r16, $warnmsg);
    
    eval {
	validation_settings(allow_unrecognized => 1);
	$r15 = check_params('simple params', {}, \%extra_param);
	validation_settings(ignore_unrecognized => 1);
	$r16 = check_params('simple params', {}, \%extra_param);
    };
    
    ok( !$@, 'call to validation_settings' ) or diag( "    message was: $@" );
    
    is( $r15->errors, 0, 'extra param separate 1');
    is( $r15->warnings, 1, 'extra param separate 2');
    is( $r15->warnings('baz'), 1, 'extra param separate 3');
    ($warnmsg) = $r15->warnings('baz');
    is( $warnmsg, "unknown parameter 'baz'", 'extra param separate 4');
    is( $r16->errors, 0, 'extra param ignore 1');
    is( $r16->warnings, 0, 'extra param ignore 2');
};


# Test that 'default' works properly

subtest 'attribute: default' => sub {
    
    my ($r1);
    
    eval {
	$r1 = check_params('default value', {}, \%missing_param);
    };
    
    ok( !$@, 'default value check' );
    diag( "    message was: $@" ) if $@;
    
    is( $r1->value('bar'), 74, 'default value 1' );
    
    eval {
	define_ruleset 'default value 2' =>
	{ optional => 'bar', valid => [POS_VALUE], default => -4 }; 
    };
    
    cmp_ok( $@, '=~', "^the default value '-4' failed all of the validators", 'bad default value' );
};


# Test that 'clean' works properly

subtest 'attribute: clean' => sub {
    
    my %string_params = ( 'foo' => 'Abc',
			  'bar' => 'dEf',
			  'baz' => 'gHI',
			  'bif' => 'JKl' );
    
    my $r1;
    
    eval {
	define_ruleset 'clean the values' => 
	{ optional => 'foo', clean => 'uc' },
	{ optional => 'bar', clean => 'lc' },
	{ optional => 'baz', clean => 'fc' },
	{ optional => 'bif', clean => sub { return $_[0] ? "AAA: $_[0]" : "AAA"; } };
	
	$r1 = check_params('clean the values', {}, \%string_params);
    };
    
    ok( !$@, "clean the values" );
    diag( "    message was: $@" ) if $@;
    
    is( $r1->value('foo'), 'ABC', 'clean the values 1' );
    is( $r1->value('bar'), 'def', 'clean the values 2' );
    is( $r1->value('baz'), 'ghi', 'clean the values 3' );
    is( $r1->value('bif'), 'AAA: JKl', 'clean the values 4' );
};


# Test that 'key' works properly

subtest 'attribute: key' => sub {

    my $r1;
    
    eval {
	define_ruleset 'param with key' =>
     	{ optional => 'foo', valid => MATCH_VALUE('[abc]+'), key => 'bar' };
	
	$r1 = check_params('param with key', {}, { foo => 'abcabc' });
    };
    
    ok( !$@, "define and check rulesets" ) || diag( "    message was: $@" );
    
    is( $r1->value('foo'), undef, "no value for 'foo' with key 'bar'" );
    is( $r1->value('bar'), 'abcabc', "value for 'bar' with key 'bar'" );
    
    my @r1err = $r1->errors;
    
    cmp_ok( @r1err, '==', 0, "no errors for 'param with key'" ) ||
	diag( "    message was: $r1err[0]" );
};


# Test that content_type works properly

subtest 'content_type' => sub {
    
    my ($r1, $r2, $r3);
    
    eval {
	define_ruleset 'content_type' =>
	    { content_type => 'ctype',  valid => ['csv', 'json', 'foo=application/foobar', '=my/type'] };
	
	$r1 = check_params('content_type', {}, { ctype => 'csv' });
	$r2 = check_params('content_type', {}, { ctype => 'foo' });
	$r3 = check_params('content_type', {}, { ctype => '' });
    };
    
    ok( !$@, "define and check rulesets" ) || diag( "    message was: $@" );
    
    is( $r1->content_type, 'text/csv', "proper content type for 'csv'" );
    is( $r2->content_type, 'application/foobar', "proper content type for 'foo'" );
    is( $r3->content_type, 'my/type', "proper content type default" );
};


# Test that 'keys', 'values', and 'raw' work properly

subtest 'keys and values' => sub {

    my ($r1, $r2, $r3, @keys, $values, $raw);
    
    eval {
	define_ruleset 'tester' =>
	    { optional => 'foo', valid => POS_VALUE, alias => ['foo_bar', 'foo_baz'] },
	    { optional => 'biff', valid => ENUM_VALUE('abc', 'def') };
	
	$r1 = check_params('tester', {}, { foo_baz => '0001', biff => 'dEF' });
	
	@keys = $r1->keys;
	$values = $r1->values;
	$raw = $r1->raw;
    };
    
    ok( !$@, "define and check rulesets" ) || diag( "    message was: $@" );
    
    ok( $r1->passed, "params passed" );
    cmp_ok( $r1->warnings, '==', 0, "no warnings" );
    
    is_deeply( \@keys, ['foo', 'biff'], "proper keys" );
    is_deeply( $values, { foo => 1, biff => 'def' }, "proper values" );
    is_deeply( $raw, { foo_baz => '0001', biff => 'dEF' }, "proper raw" );
    
    $values->{extra} = 1;
    
    my $values2 = $r1->values;
    
    ok( $values2->{extra}, "can manipulate values" );
}
