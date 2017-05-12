# test

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
local $Plan = {'cleanup' => 4} ;

lives_ok
	{
	my $context = new Eval::Context() ;

	$context->eval
		(
		PACKAGE => 'A',
		REMOVE_PACKAGE_AFTER_EVAL => 0,
		CODE => 'sub sub1{1} ;',
		) ;
		
	is(A::sub1(), 1,  'package sub still accessible') ;
	} 'no cleanup' ;
	
dies_ok
	{
	warnings_like
		{
		my $context = new Eval::Context() ;

		$context->eval
			(
			PACKAGE => 'A',
			REMOVE_PACKAGE_AFTER_EVAL => 1,
			CODE => 'sub sub2{2} ;',
			) ;
			
		A::sub2() ;
		} qr/Undefined subroutine &A::sub2/, 'forced cleanup' ;
	} 'package gone' ;
	
dies_ok
	{
	warnings_like
		{
		my $context = new Eval::Context() ;

		$context->eval
			(
			PACKAGE => 'A',
			CODE => 'sub sub3 {3} ;',
			) ;
			
		A::sub3() ;
		} qr/Undefined subroutine &A::sub3/, 'automatic cleanup' ;
	} 'package gone' ;
}
