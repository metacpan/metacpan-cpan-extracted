# add breakpoint test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings ;

use Test::More 'no_plan';
use Test::Block qw($Plan);
use Data::TreeDumper ;

# TODO create the breakpoints file dynamically and remove after test is run

use Debug::Mixin ;

{
local $Plan = {'AddBreakpoint' => 4} ;

Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'simple',
	ACTIONS => [sub{}],
	) ;

my $breakpoints = Debug::Mixin::GetBreakpoints() ;
is(keys %$breakpoints, 1, 'one breakpoint registred') ;

warning_like
	{
	is(Debug::Mixin::RemoveBreakpoints(qr/./), 1, 'one breakpoint removed') ;
	} qr/Debug::Mixin: Breakpoint '.*' removed/, "removing breakpoint warning" ;

$breakpoints = Debug::Mixin::GetBreakpoints() ;
is(keys %$breakpoints, 0, 'no breakpoint left') ;
}

{
local $Plan = {'missing argument' => 3} ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		# missing name
		) ;
	} 'missing name' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		) ;
	} 'missing actions or filter' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		FILTERS =>
			[
			sub{}
			],
		) ;
	} 'missing ALWAYS_USE_DEBUGER' ;
}

{
local $Plan = {'bad argument' => 16} ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint(UNRECOGNIZED => 1) ;
	} 'unrecogized argument' ;

throws_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		'INCORRECT_HASH'
		) ;
	} qr/odd number of arguments/, 'odd number of arguments' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => ['simple'],
		ACTIONS => [sub{}],
		) ;
	} 'bad NAME' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => 'sub',
		) ;
	} 'bad ACTIONS' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [],
		) ;
	} 'no actions' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}, 'error', sub {}],
		) ;
	} 'action is not a sub ref' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		FILTERS => 'scalar' ,
		) ;
	} 'FILTERS is not an array ref' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		FILTERS => [] ,
		) ;
	} 'empty FILTERS' ; # warning ?

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		FILTERS => ['hi'] ,
		) ;
	} 'filter is not sub ref' ;
	
dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		DEBUGGER_SUBS => '' ,
		) ;
	} 'DEBUGGER_SUBS not an array ref' ;
	
dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		DEBUGGER_SUBS => [] ,
		) ;
	} 'DEBUGGER_SUBS empty' ;
	
dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		DEBUGGER_SUBS => 
			[
				[ 'wrong type' ]
			],
		) ;
	} 'local function is not hash' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		DEBUGGER_SUBS => 
			[
				{
				NAME        => 'name',
				DESCRIPTION => "a short description",
				HELP        => "a long description", 
				SUB         => sub{},
				EXTRA       => 1,
				}
			],
		) ;
	} 'local function wrong number of arguments' ;
	
dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		DEBUGGER_SUBS => 
			[
				{
				NAMEE     => 'name',
				DESCRIPTION => "a short description",
				HELP        => "a long description", 
				SUB         => sub{},
				}
			],
		) ;
	} 'local function wrong arguments' ;
	
dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		ALWAYS_USE_DEBUGER => {} ,
		) ;
	} 'ALWAYS_USE_DEBUGER not a scalar' ;

dies_ok
	{
	Debug::Mixin::AddBreakpoint
		(
		NAME => 'simple',
		ACTIONS => [sub{}],
		ACTIVE => {} ,
		) ;
	} 'ACTIVE not a scalar' ;
}

{
local $Plan = {'automatic data and override' => 7} ;

my $line_0 = __LINE__ + 4 ; # line of the last element of the call
Debug::Mixin::AddBreakpoint
	(
	NAME    =>   'hi',
	ACTIONS =>[sub {}]
	) ;
	
my $breakpoints = Debug::Mixin::GetBreakpoints() ;

is($breakpoints->{hi}{AT}[0]{FILE}, __FILE__, 'file information') ;
is($breakpoints->{hi}{AT}[0]{LINE}, $line_0, 'line information') ;
is($breakpoints->{hi}{AT}[0]{PACKAGE},  __PACKAGE__, 'package information') ;

warning_like
	{
	my $line_1 = __LINE__ + 4 ;# line of the last element of the call
	Debug::Mixin::AddBreakpoint
		(
		NAME    =>   'hi',
		ACTIONS =>[sub {}]
		) ;
		
	#override + history
	is($breakpoints->{hi}{AT}[1]{FILE}, __FILE__, 'file information') ;
	is($breakpoints->{hi}{AT}[1]{LINE}, $line_1, 'line information') ;
	is($breakpoints->{hi}{AT}[1]{PACKAGE},  __PACKAGE__, 'package information') ;
	} qr/Redefining breakpoint 'hi' at /i, "override warning";
}

{
local $Plan = {'LoadBreakpointsFiles' => 6} ;

Debug::Mixin::RemoveAllBreakpoints() ;

# single file
lives_ok
	{
	Debug::Mixin::LoadBreakpointsFiles('t/breakpoints_file_empty') ;
	}  "single empty file loading" ;

my $breakpoints = Debug::Mixin::GetBreakpoints() ;
is(keys %$breakpoints, 0, 'no breakpoint registred') or diag DumpTree $breakpoints ;

# multiple files
lives_ok
	{
	Debug::Mixin::LoadBreakpointsFiles('t/breakpoints_file_empty', 't/breakpoints_file_multiple', 't/breakpoints_file_multiple_2') ;
	}  "multiple empty file loading" ;

$breakpoints = Debug::Mixin::GetBreakpoints() ;
is(keys %$breakpoints, 4, 'four breakpoint registred') or diag DumpTree $breakpoints ;

# error
dies_ok
	{
	Debug::Mixin::LoadBreakpointsFiles('t/breakpoints_file_error') ;
	} "syntax eror in loaded file" ;

# override
warning_like
	{
	Debug::Mixin::LoadBreakpointsFiles('t/breakpoints_file_override') ;
	} qr/Redefining breakpoint 'hi' at './, "override in loaded file" ;
}

=comment

{
die "name your test block in line below!" ;
local $Plan = {'' => } ;

is("result", "expected", "message") ;
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
