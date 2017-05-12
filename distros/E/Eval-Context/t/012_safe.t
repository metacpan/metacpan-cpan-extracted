# test

package Eval::Context ;

use strict ;
use warnings ;

use Data::TreeDumper ;
use Test::More ;
use Data::Dumper ;

#----------------------------------------------------------

package main ;

use strict ;
use warnings ;
use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
#~ use Test::NoWarnings qw(had_no_warnings);
use Test::More 'no_plan';
use Test::Block qw($Plan);

use Eval::Context ; 

$|++;

{
local $Plan = {'Default SAFE in constructor' => 1} ;

my $context = new Eval::Context(SAFE => {}) ;

throws_ok
	{
	$context->eval( CODE => 'eval "1 + 1" ;') ;
	} qr/'eval "string"' trapped by operation mask/, 'unsafe code, using default safe' ;
}

{
local $Plan = {'Default SAFE in eval' => 1} ;

my $context = new Eval::Context() ;

throws_ok
	{
	$context->eval( CODE => 'eval "1 + 1" ;', SAFE => {}) ;
	} qr/'eval "string"' trapped by operation mask/, 'unsafe code' ;
}

{
local $Plan = {'Invalid SAFE definition' => 1} ;

throws_ok
	{
	my $context = new Eval::Context(SAFE => 1) ;
	$context->eval(CODE => '') ;
	} qr/Invalid Option 'SAFE' definition/, 'Invalid SAFE definition' ;
}


{
local $Plan = {'SAFE options' => 5} ;

my $context = new Eval::Context() ;

throws_ok
	{
	$context->eval
			(
			SAFE =>{PRE_CODE => "use Xyzzy::This_Module_SHOULD_Not_Exist;\n1;\n"},
			CODE => '',
			) ;
	} qr~Can't locate Xyzzy/This_Module_SHOULD_Not_Exist.pm~, 'PRE_SAFE_CODE error';

lives_ok
	{
	$context->eval
			(
			SAFE =>{PRE_CODE => "use Data::TreeDumper;\n\n"},
			CODE => 'my $x = DumpTree({A => 1}) ;',
			) ;
	} 'PRE_SAFE_CODE' ;

throws_ok
	{
	my $output = $context->eval
			(
			CODE => '$x = 1 ;',
			SAFE => {}
			) ;
	} qr/Global symbol "\$x" requires explicit package/, 'use strict by default' ;

lives_ok
	{
	$context->eval
			(
			CODE => '$x = 1 ;',
			SAFE =>{ USE_STRICT => 0 },
			) ;
	} 'USE_STRICT' ;

lives_ok
	{
	my $compartment = new Safe('ABC') ;
	$compartment->permit('entereval') ;
		
	$context->eval(PACKAGE => 'ABC', CODE => 'eval "1 + 1" ;', SAFE => {COMPARTMENT => $compartment}) ;
	} 'COMPARTMENT' ;
}

{
local $Plan = {'SAFE PRE_CODE in same package' => 2} ;

my $context = new Eval::Context(PACKAGE => 'TEST', SAFE => {}) ;

my $output = $context->eval(CODE => 'my $x = 1; __PACKAGE__ ;') ;
is($output, 'main', 'first eval package') ;

$output = $context->eval
		(
		SAFE =>{PRE_CODE => "use Data::TreeDumper;\n\n"},
		CODE => 'DumpTree({A => 1}) ;',
		) ;

is($output,<<EOT,'Test STDOUT') or diag DumpTree $context ;

`- A = 1  [S1]
EOT
}

{
# test if access to caller side functions is possible in safe
local $Plan = {'multiple evaluations in the same SAFE' => 2} ;

my $get_117 = sub{117} ;
my $result = new Eval::Context(PACKAGE => 'TEST')
		->eval(SAFE => {}, CODE => 'get_117() ;', INSTALL_SUBS => {get_117 => $get_117}) ;
		
is($result, 117, 'sub pushed into safe context') ;

my $get_118 = sub{118} ;
$result = new Eval::Context(PACKAGE => 'TEST')
		->eval(SAFE => {}, CODE => 'get_118() ;', INSTALL_SUBS => {get_118 => $get_118}) ;
		
is($result, 118, 'new sub pushed into same safe context') ;
}

{
#~ # test if access to persistent saving functions on eval side
local $Plan = {'SAFE access to persistent functions' => 1} ;

my $context = new Eval::Context
		(
		EVAL_SIDE_PERSISTENT_VARIABLES =>
			{
			CATEGORY => 'TEST',
			SAVE => { NAME => 'SavePersistent', VALIDATOR => sub{}, },
			GET => { NAME => 'GetPersistent', VALIDATOR => sub {}},
			},
		SAFE => {},
		) ;

$context->eval(CODE => 'my $variable = 24 ; SavePersistent(\'$variable\', $variable) ;') ;

my $output = $context->eval(CODE => 'my $variable = GetPersistent(\'$variable\') ;') ;
is($output, 24, 'access to persistent functionality') or diag DumpTree $context ;
}

{
local $Plan = {'SAFE caller context' => 6} ;

my $context = new Eval::Context
		(
		SAFE => {},
		) ;
		
lives_ok
	{
	$context->eval(CODE => '$variable', INSTALL_VARIABLES => [ ['$variable', 42] ]) ;
	}  'void context' ;
	
lives_ok
	{
	my $output = $context->eval(CODE => '$variable', INSTALL_VARIABLES => [ ['$variable', 42] ]) ;
	is($output, 42, 'right value in scalar context') ;
	}  'scalar context' ;
	
lives_ok
	{
	my @output = $context->eval(CODE => '$variable', INSTALL_VARIABLES => [ ['$variable', 42] ]) ;
	is_deeply(\@output, [42], 'right value in array  context') ;
	}  'array context' ;

throws_ok
	{
	$context->eval(CODE => 'die "died withing safe"',) ;
	} qr/died withing safe/, 'die within a safe' ;
}

{
local $Plan = {'SAFE and croak' => 3} ;

my $context = new Eval::Context
		(
		SAFE => 
			{
			PRE_CODE => 'use Carp  ;',
			},
		) ;
		
my $output = $context->eval(CODE => '$variable', INSTALL_VARIABLES => [ ['$variable', 42] ]) ;
is($output, 42, 'right value in scalar context') ;

throws_ok
	{
	# Eval context returns the code as an error, make sure the error is not part of the code
	$context->eval(CODE => "my \$error = 'this_i' . 's_the_croak_message';\ncroak(\$error) ;",) ;
	} qr/this_is_the_croak_message/, 'croak within a safe' ;

#~ diag DumpTree $context  ;
#~ diag $@ ;

throws_ok
	{
	# Eval context returns the code as an error, make sure the error is not part of the code
	$context->eval(CODE => 'my $error = "this_i" . "s_the_die_message";  die $error ;',) ;
	} qr/this_is_the_die_message/, 'die within a safe while using Carp' ;
	
#~ diag $@ ;

}
