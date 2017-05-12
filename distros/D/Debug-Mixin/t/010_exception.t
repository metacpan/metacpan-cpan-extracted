# exception test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Debug::Mixin ; 

{
local $Plan = {'filters and actions run in eval blocks' => 1} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{die 'unexpectedly'},
		],
	ACTIVE => 1,
	) ;

throws_ok
	{
	Debug::Mixin::CheckBreakpoints() ;
	} qr/CheckBreakpoints: Caught exception while running breakpoint action/, 'exception in action' ;
	
#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'filters and actions run in eval blocks' => 1} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{return(0)},
		],
	ACTIVE => 1,
	FILTERS =>
		[
		sub{die 'unexpectedly'},
		]
	) ;

throws_ok
	{
	Debug::Mixin::CheckBreakpoints() ;
	} qr/CheckBreakpoints: Caught exception while running breakpoint filter/, 'exception in filter' ;
	
#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

=comment

{
local $Plan = {'' => } ;

is(result, expected, "message") ;
dies_ok
	{
	
	} "" ;

lives_ok
	{
	
	} "" ;

like(result, qr//, '') ;

warning_like
	{
	} qr//i, "";

is_deeply
	(
	generated,
	[],
	'expected values'
	) ;

}

=cut
