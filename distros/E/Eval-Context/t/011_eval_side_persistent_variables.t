# test

package Eval::Context ;

use strict ;
use warnings ;

use Data::TreeDumper ;
use Test::More ;
use Data::Dumper ;

#----------------------------------------------------------

package some_object ;

use strict ;
use warnings ;

sub new {bless { VALUE => $_[1] }, $_[0];}
sub GetValue {$_[0]->{VALUE} ;}
sub AddOne{$_[0]->{VALUE} += 1 ;}
sub GetDump {Data::Dumper->Dump([$_[0]]) ;}

#----------------------------------------------------------

package main ;

use strict ;
use warnings ;
use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);
use Test::More 'no_plan';
use Test::Block qw($Plan);

use Eval::Context 'constants' ; 

{
local $Plan = {'EVAL SIDE PERSISTENCE' => 5} ;

my $context = new Eval::Context
		(
		EVAL_SIDE_PERSISTENT_VARIABLES =>
			{
			CATEGORY => 'TEST',
			SAVE => 
				{
				NAME => 'SavePersistent',
				VALIDATOR => sub 
					{
					my ($self, $name, $value, $package) = @_ ;
					},
				},
				
			GET => 
				{
				NAME => 'GetPersistent',
				VALIDATOR => sub {}
				},
			},
		) ;

$context->eval
		(
		CODE => <<'EOC' ,
my $variable = 24 ;
SavePersistent('$variable', $variable) ;
EOC
			) ;

my $output = $context->eval
			(
			CODE => <<'EOC' ,
my $variable = GetPersistent('$variable') ;
EOC
			) ;
is($output, 24) or diag DumpTree $context ;

# test with reference and object
my $caller_side_object = new some_object(5) ;
my $caller_side_reference = {A => 1} ;

$context->eval
		(
		 INSTALL_VARIABLES => 
			[
			['$caller_side_object', $caller_side_object] ,
			['$caller_side_reference', $caller_side_reference] ,
			],
		CODE => <<'EOC' ,
SavePersistent
	(
	'$reference' => $caller_side_reference,
	'$object' =>  $caller_side_object
	) ;
EOC
			) ;

my ($reference, $object) = $context->eval
				(
				CODE => <<'EOC' ,
GetPersistent('$reference','$object') ;
EOC
				) ;

is_deeply($reference, $caller_side_reference, 'reference made persistent OK') ;
is_deeply($object, $caller_side_object, 'object made persistent OK') ;
isa_ok($object, ref($caller_side_object), 'object in right class') ;

throws_ok
	{
	my $output = $context->eval
				(
				CODE => <<'EOC' ,
	SavePersistent('variable', 1, 2) ;
EOC
				) ;
	} qr/eval-side persistence handler got unexpected number of arguments/, 'wrong number of arguments' ;
}

{
local $Plan = {'invalid input to EVAL_SIDE_PERSISTENT_VARIABLES' => 6} ;

throws_ok
	{
	my $context = new Eval::Context
			(
			EVAL_SIDE_PERSISTENT_VARIABLES =>
				{
				GET => 
					{
					NAME => 'GET',
					VALIDATOR => sub {}
					},
				},
			) ;
			
	$context->eval(CODE => "1 ;\n") ;
	} qr/'EVAL_SIDE_PERSISTENT_VARIABLES' missing handler definition/, 'invalid input, handler missing' ;

throws_ok
	{
	my $context = new Eval::Context
			(
			EVAL_SIDE_PERSISTENT_VARIABLES =>
				{
				SAVE => 
					{
					NAME => '',
					VALIDATOR => sub {}
					},
					
				GET => 
					{
					NAME => 'NAME',
					VALIDATOR => sub {}
					},
				},
			) ;
			
	$context->eval(CODE => "1 ;\n") ;
	} qr/'EVAL_SIDE_PERSISTENT_VARIABLES' invalid definition/, 'invalid input, name is empty' ;

throws_ok
	{
	my $context = new Eval::Context
			(
			EVAL_SIDE_PERSISTENT_VARIABLES =>
				{
				SAVE => 
					{
					NAME => [],
					VALIDATOR => sub {}
					},
					
				GET => 
					{
					NAME => 'NAME',
					VALIDATOR => sub {}
					},
				},
			) ;
			
	$context->eval(CODE => "1 ;\n") ;
	} qr/'EVAL_SIDE_PERSISTENT_VARIABLES' invalid definition/, 'invalid input, name is not a string' ;

throws_ok
	{
	my $context = new Eval::Context
			(
			EVAL_SIDE_PERSISTENT_VARIABLES =>
				{
				SAVE => 
					{
					NAME => 'SAVE',
					},
					
				GET => 
					{
					NAME => 'GET',
					VALIDATOR => sub {}
					},
				},
			) ;
			
	$context->eval(CODE => "1 ;\n") ;
	} qr/'EVAL_SIDE_PERSISTENT_VARIABLES' invalid definition/, 'invalid input, validator is missing' ;

throws_ok
	{
	my $context = new Eval::Context
			(
			EVAL_SIDE_PERSISTENT_VARIABLES =>
				{
				SAVE => 
					{
					NAME => 'SAVE',
					VALIDATOR => 1 ,
					},
					
				GET => 
					{
					NAME => 'GET',
					VALIDATOR => sub {}
					},
				},
			) ;
			
	$context->eval(CODE => "1 ;\n") ;
	} qr/'EVAL_SIDE_PERSISTENT_VARIABLES' invalid definition/, 'invalid input, validator is not a sub' ;

throws_ok
	{
	my $context = new Eval::Context(EVAL_SIDE_PERSISTENT_VARIABLES => []) ;
	$context->eval(CODE => "1 ;\n") ;
	} qr/'EVAL_SIDE_PERSISTENT_VARIABLES' isn't a hash reference/, 'invalid input EVAL_SIDE_PERSISTENT_VARIABLES' ;

}

{
local $Plan = {'handlers differently named' => 1} ;

throws_ok
	{
	my $context = new Eval::Context
			(
			PACKAGE => 'ABC',
			REMOVE_PACKAGE_AFTER_EVAL => 0,
			EVAL_SIDE_PERSISTENT_VARIABLES =>
				{
				CATEGORY => 'TEST',
				SAVE => 
					{
					NAME => 'SAME_NAME',
					VALIDATOR => sub {}
					},
					
				GET => 
					{
					NAME => 'SAME_NAME',
					VALIDATOR => sub {}
					},
				},
			) ;
			
	$context->eval(CODE => "1 ;\n") ;
	} qr/eval-side persistence handlers have the same name/, 'handlers differently named' ;
}

{
local $Plan = {'handlers automatically removed' => 2} ;

my $context = new Eval::Context
		(
		PACKAGE => 'ABC',
		REMOVE_PACKAGE_AFTER_EVAL => 0,
		EVAL_SIDE_PERSISTENT_VARIABLES =>
			{
			CATEGORY => 'TEST',
			SAVE => 
				{
				NAME => 'SavePersistent',
				VALIDATOR => sub 
					{
					my ($self, $name, $value, $package) = @_ ;
					
					#~ $self->DIE ;
					},
				},
				
			GET => 
				{
				NAME => 'GetPersistent',
				VALIDATOR => sub {}
				},
			},
		) ;

$context->eval
	(
	CODE => <<'EOC' ,
my $variable = 24 ;
SavePersistent('$variable', $variable) ;
EOC
	) ;
throws_ok
	{
	$context->eval
		(
		EVAL_SIDE_PERSISTENT_VARIABLES => undef,
		CODE => 'my $variable = GetPersistent("variable") ;',
		) ;
	} qr/No Persistence allowed on eval-side in package 'ABC'/, 'handlers automatically removed' ;
			
throws_ok
	{
	$context->eval
		(
		EVAL_SIDE_PERSISTENT_VARIABLES => undef,
		CODE => 'SavePersistent("variable", 42) ;',
		) ;
	} qr/No Persistence allowed on eval-side in package 'ABC'/, 'handlers automatically removed' ;
			
}

{
local $Plan = {'validators' => 2} ;

my $context = new Eval::Context
		(
		PACKAGE => 'ABC',
		REMOVE_PACKAGE_AFTER_EVAL => 0,
		EVAL_SIDE_PERSISTENT_VARIABLES =>
			{
			CATEGORY => 'TEST',
			SAVE => 
				{
				NAME => 'SavePersistent',
				VALIDATOR => sub 
					{
					my ($self, $name, $value) = @_ ;
					
					$self->{INTERACTION}{DIE}->
						(
						$self,
						"SavePersistent: name '$name' doesn't start with A!"
						)  unless $name =~ /^A/ ;
					},
				},
				
			GET => 
				{
				NAME => 'GetPersistent',
				VALIDATOR => sub 
					{
					my ($self, $name, $value) = @_ ;
					
					$self->{INTERACTION}{DIE}->
						(
						$self,
						"GetPersistent: name '$name' doesn't start with A!"
						)  unless $name =~ /^A/ ;
					},
				},
			},
		) ;

throws_ok
	{
	$context->eval
		(
		CODE => <<'EOC' ,
	my $variable = 24 ;
	SavePersistent('A', 1) ;
	SavePersistent('B', 2) ;
EOC
		) ;
	} qr/SavePersistent: name 'B' doesn't start with A/, 'Save validator' ;

throws_ok
	{
	$context->eval
		(
		CODE => <<'EOC' ,
	GetPersistent('A') ;
	GetPersistent('C') ;
EOC
		) ;
	} qr/GetPersistent: name 'C' doesn't start with A/, 'Get validator' ;
}

