
use strict ;
use warnings ;

use Data::TreeDumper ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Eval::Context ; 

{
local $Plan = {'new arguments' => 7} ;

lives_ok
	{
	my @parameters = map {$_ => 1}
				qw(
				NAME
				PRE_CODE
				POST_CODE
				PERL_EVAL_CONTEXT
				PACKAGE
				DISPLAY_SOURCE_IN_CONTEXT
				FILE LINE
				) ;
				
	push @parameters, 'INTERACTION', {} ;

	my $context = new Eval::Context(@parameters) ;
	} 'accepts all defined arguments' ;

lives_ok
	{
	my $context = new Eval::Context(NAME => '') ;
	$context->eval(CODE => '') ;
	is($context->{NAME}, 'Anonymous eval context',  'empty name is makes object anonymous') ;
	} 'empty name' ;
	
lives_ok
	{
	my $context = new Eval::Context(NAME => undef) ;
	$context->eval(CODE => '') ;
	is($context->{NAME}, 'Anonymous eval context',  'undefined name is makes object anonymous') ;
	} 'undefined name' ;

throws_ok
	{
	my $context = new Eval::Context(1) ;
	} qr/Invalid number of argument/, 'invalid number of parameters' ;

throws_ok
	{
	my $context = new Eval::Context(SOMETHING_UNEXPECTED => 1) ;
	} qr/Invalid Option 'SOMETHING_UNEXPECTED'/, 'invalid parameter' ;
}

{
local $Plan = {'new sub subroutines' => 11} ;

# check the subroutines and get the needed code coverage

my $object = {NAME => 'test', INTERACTION => {}} ;
Eval::Context::SetInteractionDefault($object) ;

lives_ok
	{
	Eval::Context::CheckOptionNames($object, {FILE => 1, LINE => 1}) ;
	} 'accepts a hash ref as valid options definition' ;
	
lives_ok
	{
	Eval::Context::CheckOptionNames($object, [qw(FILE LINE)]) ;
	} 'accepts an array ref as valid options definition' ;

throws_ok
	{
	Eval::Context::CheckOptionNames($object, '') ; #doesn't matter what is passed as argument
	} qr/Invalid 'valid_options' definition/, 'invalid option definition' ;

throws_ok
	{
	Eval::Context::CheckOptionNames($object, [qw(FILE LINE)], FILE => 1) ; 
	}qr/Incomplete option FILE::LINE/, 'missing LINE' ;

throws_ok
	{
	Eval::Context::CheckOptionNames($object, [qw(FILE LINE)], LINE => 1) ;
	} qr/Incomplete option FILE::LINE/, 'missing FILE' ;

#-------------------------------------------------------------------

my $interaction = {INTERACTION => {}} ;
Eval::Context::SetInteractionDefault($interaction) ;

is(defined $interaction->{INTERACTION}{INFO}, 1, 'interaction INFO defined') ;
is(defined $interaction->{INTERACTION}{WARN}, 1, 'interaction WARN defined') ;
is(defined $interaction->{INTERACTION}{DIE}, 1, 'interaction DIE defined') ;

#-------------------------------------------------------------------

my $the_sub = sub{} ;
$interaction = 
	{
	INTERACTION => 
		{
		INFO => $the_sub,
		WARN => $the_sub,
		DIE => $the_sub,
		}
	} ;
Eval::Context::SetInteractionDefault($interaction) ;

is($interaction->{INTERACTION}{INFO}, $the_sub, 'interaction INFO unchanged') ;
is($interaction->{INTERACTION}{WARN}, $the_sub, 'interaction WARN unchanged') ;
is($interaction->{INTERACTION}{DIE}, $the_sub, 'interaction DIE unchanged') ;
}
