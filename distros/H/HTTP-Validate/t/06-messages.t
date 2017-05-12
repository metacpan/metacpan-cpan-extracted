#!perl

use lib 'lib';

use strict;
use Test::More tests => 2;

use HTTP::Validate qw(:keywords :validators);


# Start by testing that we can create a new object with custom error messages.

my @messages = (
    ERR_INVALID => 'invalid {param} : {value}',
    ERR_BAD_VALUES => 'bad_values {param} : {value}',
    ERR_MULT_NAMES => 'mult_names {param}',
    ERR_MULT_VALUES => 'mult_values {param} : {value}',
    ERR_MANDATORY => 'mandatory {param}',
    ERR_TOGETHER => 'together {param}',
    ERR_AT_MOST => 'at_most {param}',
    ERR_REQ_SINGLE => 'req_single {param}',
    ERR_REQ_MULT => 'req_mult {param}',
    ERR_REQ_ONE => 'req_one {param}',
    ERR_MEDIA_TYPE => 'media_type {param} : {value}',
    ERR_DEFAULT => 'default',
   );

my @bad_messages = (
    ERR_NOT_THERE => 'bad',
   );

my ($valtest, $valtest2);


subtest 'set custom messages' => sub {
    
    $valtest = new_ok( 'HTTP::Validate' => \@messages, 'new with custom messages' );
    
    eval {
	my $v2 = HTTP::Validate->new(\@bad_messages);
    };
    
    ok( $@, 'new with bad message key' );
    
    eval {
	$valtest2 = HTTP::Validate->new;
	$valtest2->validation_settings(@messages);
    };
    
    ok( !$@, 'set custom messages' ) or diag("    message was: $@");
    
    eval {
	$valtest->validation_settings(@bad_messages);
    };
    
    ok( $@, 'bad message key with validation_settings' );

};


subtest 'check custom messages' => sub {
    
    eval {
	$valtest->define_ruleset('test 1' =>
	    { param => 'foo', valid => POS_VALUE, alias => 'fooz' },
	    { mandatory => 'bar', valid => POS_VALUE,
	      ERR_INVALID => "test_invalid" },
	    { param => 'tweedledee', valid => POS_VALUE },
	    { param => 'tweedledum', valid => POS_VALUE },
	    { together => [ 'tweedledee', 'tweedledum' ] });
	
	$valtest->define_ruleset('test 1a' =>
	    { param => 'foo', valid => POS_VALUE,
	      ERR_INVALID => "test_invalid", warn => 1 });
	
	$valtest->define_ruleset('test 1b' =>
	    { content_type => 'ct', valid => ['html', 'json'] });
	
	$valtest2->define_ruleset('test 2a' =>
	    { param => 'foo', valid => POS_VALUE },
	    { param => 'bar', valid => POS_VALUE },
	    { at_most_one => ['foo', 'bar'] });
	
	$valtest2->define_ruleset('test 2b' =>
	    { param => 'baz', valid => POS_VALUE, 
	      list => ',', bad_value => 'ERROR' });
	
	$valtest2->define_ruleset('test 2c' =>
	    { allow => 'test 2a' },
	    { allow => 'test 2b' },
	    { require_one => [ 'test 2a', 'test 2b' ] });
	
	$valtest2->define_ruleset('test 2d' =>
	    { allow => 'test 2a' },
	    { allow => 'test 2b' },
	    { require_one => [ 'test 2a', 'test 2b' ],
	      warn => 1 });
	
	$valtest2->define_ruleset('test 2e' =>
	    { allow => 'test 2a' },
	    { allow => 'test 2b' },
	    { require_any => [ 'test 2a', 'test 2b' ],
	      warn => "test_warning" });
	
	$valtest2->define_ruleset('test 2f' =>
	    { allow => 'test 2a' },
	    { allow => 'test 2b' },
	    { require_one => [ 'test 2a', 'test 2b' ],
	      ERR_REQ_MULT => "test_mult",
	      ERR_REQ_ONE => "test_one" });
	
    };
    
    unless ( ok( !$@, 'define test rulesets' ) )
    {
	diag("    message was: $@");
	return;
    }
    
    my $r1 = $valtest->check_params('test 1', {}, [ foo => 1 ]);
    my @e1 = $r1->errors;
    
    is( @e1, 1, 'error count 1' );
    is( $e1[0], "mandatory 'bar'", 'error mandatory' );
    
    my $r2 = $valtest->check_params('test 1', {}, [ bar => 1, foo => 2, fooz => 3 ]);
    my @e2 = $r2->errors;
    
    is( @e2, 1, 'error count 2' );
    is( $e2[0], "mult_names 'foo', 'fooz'", 'error mult_names');
    
    my $r2a = $valtest->check_params('test 1', {}, [ bar => 1, foo => 2, foo => 3 ]);
    my @e2a = $r2a->errors;
    
    is( @e2a, 1, 'error count 2a' );
    is( $e2a[0], "mult_values 'foo' : '2', '3'", 'error mult_values');
    
    my $r3 = $valtest2->check_params('test 2a', {}, [ foo => 1, bar => 2 ]);
    my @e3 = $r3->errors;
    
    is( @e3, 1, 'error count 3' );
    is( $e3[0], "at_most 'foo', 'bar'", 'error at_most' );
    
    my $r4 = $valtest->check_params('test 1', {}, [ bar => 1, tweedledee => 2 ]);
    my @e4 = $r4->errors;
    
    is( @e4, 1, 'error count 4' );
    is( $e4[0], "together 'tweedledee', 'tweedledum'", 'error together' );
    
    my $r5 = $valtest2->check_params('test 2b', {}, [ baz => '1.2,3.4' ]);
    my @e5 = $r5->errors;
    my @w5 = $r5->warnings;
    
    is( @e5, 1, 'error count 5' );
    is( $e5[0], "bad_values 'baz' : '1.2', '3.4'", 'error bad_values' );
    is( @w5, 2, 'warning count 5' );
    
    my $r6 = $valtest2->check_params('test 2c', {}, [ foo => 1, baz => 2 ]);
    my @e6 = $r6->errors;
    
    is( @e6, 1, 'error count 6' );
    is( $e6[0], "req_one '(A)', 'foo', 'bar', '(B)', 'baz'", 'error req_one' );
    
    my $r7 = $valtest2->check_params('test 2c', {}, []);
    my @e7 = $r7->errors;
    
    is( @e7, 1, 'error count 7' );
    is( $e7[0], "req_mult 'foo', 'bar', 'baz'", 'error req_mult' );
    
    my $r8 = $valtest2->check_params('test 2b', {}, []);
    my @e8 = $r8->errors;
    
    is( @e8, 1, 'error count 8' );
    is( $e8[0], "req_single 'baz'", 'error req_single' );
    
    my $r9 = $valtest->check_params('test 1b', {}, []);
    my @e9 = $r9->errors;
    
    is( @e9, 1, 'error count 9' );
    is( $e9[0], "media_type 'ct' : 'html', 'json'", 'error media_type' );
    
    my $r10 = $valtest2->check_params('test 2d', {}, []);
    my @e10 = $r10->errors;
    my @w10 = $r10->warnings;
    
    is( @e10, 0, 'error count 10' );
    is( @w10, 1, 'warning count 10' );
    is( $w10[0], "req_mult 'foo', 'bar', 'baz'", 'error req_mult' );
    
    my $r11 = $valtest2->check_params('test 2e', {}, []);
    my @e11 = $r11->errors;
    my @w11 = $r11->warnings;
    
    is( @e11, 0, 'error count 11' );
    is( @w11, 1, 'warning count 11' );
    is( $w11[0], "test_warning", 'error test_warning' );
    
    my $r12 = $valtest2->check_params('test 2f', {}, []);
    my @e12 = $r12->errors;
    my @w12 = $r12->warnings;
    
    is( @e12, 1, 'error count 12' );
    is( @w12, 0, 'warning count 12' );
    is( $e12[0], "test_mult", 'error test_mult 2' );
    
    my $r13 = $valtest2->check_params('test 2f', {}, [ foo => 1, bar => 2, baz => 3 ]);
    my @e13 = sort $r13->errors;
    my @w13 = $r13->warnings;
    
    is( @w13, 0, 'warning count 13' );
    is_deeply( \@e13, [ "at_most 'foo', 'bar'", "test_one" ], 'error messages 13' );
    
    my $r14 = $valtest->check_params('test 1', {}, [ bar => 0 ]);
    my @e14 = sort $r14->errors;
    my @w14 = $r14->warnings;
    
    is_deeply( \@e14, [ "test_invalid" ], 'error messages 14' );
    is( @w14, 0, 'warning count 14' );
    
    my $r15 = $valtest->check_params('test 1a', {}, [ foo => -5 ]);
    my @e15 = sort $r15->errors;
    my @w15 = sort $r15->warnings;
    
    is_deeply( \@w15, [ "test_invalid" ], 'warning messages 15' );
    is( @e15, 0, 'error count 15' );
    
    
};


