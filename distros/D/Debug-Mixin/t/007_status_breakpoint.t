# status test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Debug::Mixin ; 

{
local $Plan = {'ALWAYS_USE_DEBUGGER' => 2} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{return(0)},# do NOT jump in debugger
		],
	ACTIVE => 1,
	) ;

warning_like
	{
	Debug::Mixin::ActivateAlwaysUseDebugger(qr/sim/) ;
	} qr/Breakpoint 'simple' will always activate the perl debugger/, "always activate warning" ;
	
is(Debug::Mixin::CheckBreakpoints(), 1, 'jumping into debugger') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'ALWAYS_USE_DEBUGGER' => 2} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{return(0)},# do NOT jump in debugger
		],
	ACTIVE => 1,
	ALWAYS_USE_DEBUGGER => 1,
	) ;

warning_like
	{
	Debug::Mixin::DeactivateAlwaysUseDebugger(qr/./) ;
	} qr/Breakpoint 'simple' will NOT always activate the perl debugger/, "NOT always activate warning" ;

is(Debug::Mixin::CheckBreakpoints(), 0, 'no jumping into debugger') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}


{
local $Plan = {'ACTIVE' => 2} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{return(0)},# do NOT jump in debugger
		],
	ALWAYS_USE_DEBUGGER => 1,
	) ;

warning_like
	{
	Debug::Mixin::ActivateBreakpoints(qr/SIMPLE/i) ;
	} qr/Breakpoint 'simple' activated/, "activated warning" ;

is(Debug::Mixin::CheckBreakpoints(), 1, 'jumping into debugger') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'ACTIVE' => 2} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{return(0)},# do NOT jump in debugger
		],
	ACTIVE => 1,
	ALWAYS_USE_DEBUGGER => 1,
	) ;

warning_like
	{
	Debug::Mixin::DeactivateBreakpoints(qr/simple/) ;
	} qr/Breakpoint 'simple' deactivated/, "deactivated warning" ;

is(Debug::Mixin::CheckBreakpoints(), 0, 'no jumping into debugger') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

=comment

{
die "name your test block in line below!" ;
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
