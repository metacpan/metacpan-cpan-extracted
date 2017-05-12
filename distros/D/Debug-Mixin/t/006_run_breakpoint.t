# add breakpoint test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);

use Debug::Mixin ; 

{
local $Plan = {'run actions' => 2} ;

my ($action_1, $action_2, $action_3) ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{$action_1++; return(1)},# jump in debugger
		sub{$action_2++; return(1)}, # jump in debugger
		sub{$action_3++; return(0);}, # do not jump in debugger
		],
	) ;

Debug::Mixin::EnableDebugger(0) ;

my $jump_into_debugger = Debug::Mixin::CheckBreakpoints() ;

is(! defined $action_1 && !defined $action_2 && ! defined $action_3 , 1, 'no subs called, module not enabled') ;
is($jump_into_debugger, 0, 'no active breakpoint') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
Debug::Mixin::EnableDebugger(1) ;
}


{
local $Plan = {'run actions' => 2} ;

my ($action_1, $action_2, $action_3) ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{$action_1++; return(1)},# jump in debugger
		sub{$action_2++; return(1)}, # jump in debugger
		sub{$action_3++; return(0);}, # do not jump in debugger
		],
	) ;

my $jump_into_debugger = Debug::Mixin::CheckBreakpoints() ;

is(! defined $action_1 && !defined $action_2 && ! defined $action_3 , 1, 'no subs called, no active breakpoint') ;
is($jump_into_debugger, 0, 'no active breakpoint') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'run actions' => 2} ;

my ($action_1, $action_2, $action_3) ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{$action_1++; return(1)},# jump in debugger
		sub{$action_2++; return(1)}, # jump in debugger
		sub{$action_3++; return(0);}, # do not jump in debugger
		],
	ACTIVE => 1,
	) ;

my $jump_into_debugger = Debug::Mixin::CheckBreakpoints() ;

is($action_1 + $action_2 + $action_3 , 3, 'action subs called') ;
is($jump_into_debugger, 2, 'two subs jumping in debugger') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'ALWAYS_USE_DEBUGGER' => 1} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{return(0)},# do NOT jump in debugger
		],
	ACTIVE => 1,
	) ;

my $jump_into_debugger = Debug::Mixin::CheckBreakpoints() ;

is($jump_into_debugger, 0, 'no jumpng into debugger') ;

Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'ALWAYS_USE_DEBUGGER' => 1} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{return(0)},# do NOT jump in debugger
		],
	ALWAYS_USE_DEBUGGER => 1,
	ACTIVE => 1,
	) ;


is(Debug::Mixin::CheckBreakpoints(), 1, 'jumping into debugger') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'modify a breakpoint state from another breakpoint' => 2} ;

my ($simple_action, $modifier_action) ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{$simple_action++; return(0)},
		],
	ACTIVE => 1,
	) ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple modifier',
	ACTIONS => 
		[
		sub
			{
			$modifier_action++;
			my $breakpoints = Debug::Mixin::GetBreakpoints() ;
			$breakpoints->{simple}{ACTIVE} = 0 ;
			},
		],
	ACTIVE => 1,
	) ;

my $jump_into_debugger = Debug::Mixin::CheckBreakpoints() ;

is($simple_action + $modifier_action , 2 , 'action subs called') ;

($simple_action, $modifier_action)  = (0, 0) ;

$jump_into_debugger = Debug::Mixin::CheckBreakpoints() ;

use Data::TreeDumper ;
is($simple_action + $modifier_action, 1, 'only modifier subs called') or diag(DumpTree Debug::Mixin::GetBreakpoints()) ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'modify bp' => 5} ;

my @args =
	(
	FIRST_ARG => [],
	SECOND_ARG => 'second arg',
	) ;
	
my (@received_args) ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{@received_args = @_ ; return(0)},
		],
	ACTIVE => 1,
	) ;

my $call_line = __LINE__ + 1 ;
Debug::Mixin::CheckBreakpoints(@args) ;

is_deeply
	(
	[splice @received_args, 0, 4],
	\@args,
	'arguments to CheckBreakpoints'
	) ;

is($received_args[0], 'DEBUG_MIXIN_BREAKPOINT', 'breakpoint element automatically added') ;
is (ref $received_args[1], 'HASH', 'breakpoint element is hash') ;

is($received_args[2], 'DEBUG_MIXIN_CALLED_AT', 'breakpoint call location automatically added') ;
is_deeply
	(
	$received_args[3],
	{
	FILE => __FILE__,
	LINE => $call_line,
	},
	'called at'
	) ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'filters' => 1} ;

my ($action) ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{$action++ ; return(0)},
		],
	ACTIVE => 1,
	FILTERS =>
		[
		sub { my $args = @_ ; 0; }, # do not run
		sub { my (%args) = @_ ; exists $args{FIRST_ARG}}
		]
	) ;

my @args =
	(
	FIRST_ARG => [],
	SECOND_ARG => 'second arg',
	) ;

Debug::Mixin::CheckBreakpoints(@args) ;

is($action, 1, 'filter arguments pass') ;

#cleanup
Debug::Mixin::RemoveAllBreakpoints() ;
}

{
local $Plan = {'regex filters' => 1} ;

my ($action) ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => 
		[
		sub{$action++ ; return(0)},
		],
	ACTIVE => 1,
	FILTERS =>
		[
		sub { my (%args) = @_ ; exists $args{THIRD_ARG} }
		]
	) ;

my @args =
	(
	FIRST_ARG => [],
	SECOND_ARG => 'second arg',
	) ;

Debug::Mixin::CheckBreakpoints(@args) ;

is($action, undef, 'filter arguments fail') ;

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
