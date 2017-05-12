# subs test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Debug::Mixin
		{
		DEBUGGER_SUBS => 
			[
				{
				NAME        => 'RunModuleDebuggerSub',
				ALIASES     => [qw(dm_rmds)],
				DESCRIPTION => "a short description for a module sub ",
				HELP        => "a long, possibly multi line, description displayed\n"
						. "when the user needs it",
				SUB         => sub{ print "RunModuleDebuggerSub\n"; },
				},
			],
		} ;

SKIP:
{
local $Plan = {'help subs' => 1} ;

Debug::Mixin::AddBreakpoint
	(
	NAME => 'simple',
	ACTIVE => 1,
	ACTIONS => [sub{}],
	DEBUGGER_SUBS => 
		[
			{
			NAME     => 'RunBreakpointDebuggerSub',
			DESCRIPTION => "a short description for a breakpoint sub",
			HELP        => "a long description,\nverylong ...", 
			SUB         => sub
					{
					use Data::TreeDumper ;
					print DumpTree(\@_, 'RunBreakpointDebuggerSub') ;
					},
			} ,
			{
			NAME     => 'AnotherRunBreakpointDebuggerSub',
			DESCRIPTION => "a short description for a breakpoint sub",
			HELP        => "a long description,\nverylong ...", 
			SUB         => sub
					{
					use Data::TreeDumper ;
					print DumpTree(\@_, 'AnotherRunBreakpointDebuggerSub') ;
					},
			}
		],
	) ;

Debug::Mixin::CheckBreakpoints() ;

skip "unimplemented" => $Plan;

# at any point DebuggerSub and dm_ds are callable from the debugger
# help for module sub is available through the normal DM comands
# display of what module subs are available from normal DM commands

# after running breakpoint, RunBreakpointDebuggerSub and dm_rbds made available to the user
# available commands are displayed
# help available on request

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
