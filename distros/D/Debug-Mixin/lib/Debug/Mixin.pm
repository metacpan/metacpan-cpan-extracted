
package Debug::Mixin ;
use base Exporter ;

use strict ;
use warnings ;

BEGIN 
{
use vars qw ($VERSION @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.4' ;
@EXPORT_OK   = qw (IsDebuggerEnabled CheckBreakpoint);
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

use Carp qw(croak carp confess cluck);
use Data::TreeDumper ;

use Sub::Install;
use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use Tie::Hash::Indexed ;
use List::MoreUtils qw(any) ;

#-------------------------------------------------------------------------------

=head1 NAME

 Debug::Mixin - Make your applications and modules easier to debug

=head1 SYNOPSIS

package my_module ;

	# load Debug::Mixin
	use Debug::Mixin
		{
		BANNER     => "my banner",
		
		# available at any point in the debugger
		DEBUGGER_SUBS => 
			[
			
				{
				NAME        => CheckDependencyMatrix
				ALIASES     => [qw(dm_cdm cdm)],
				DESCRIPTION => "a short description of what this sub is for",
				HELP        => "a long, possibly multi line description displayed"
						. "when the user needs it",
				SUB         => sub{},
				}
			],
		} ;
		
	# add breakpoints
	AddBreakpoint
		(
		NAME    =>   'hi'
		
		FILTERS =>
			[
			sub 
				{
				my (%filter) = @_ ;
				$filter{ARGS}{TYPE} eq 'DEPEND' ; # true will enable the actions
				}
			]
			
		ACTIONS =>
			[
			sub 
				{
				my (%filter) = @_ ;
				
				print DumpTree $filter{ARGS}{COMPLEX_ELEMENT} ;
				
				return JUMP_TO_DEBUGGER # want to jump into debugger
				}
			]
			
		DEBUGGER_SUBS=>
			[
				{
				NAME        => 'BreakpointDebuggerSub',
				DESCRIPTION => "a short description of what this sub is for",
				HELP        => "a long, possibly multi line description displayed"
						. "when the user needs it",
				SUB         => sub{},
				}
			]
			
		LOCAL_STORAGE => {}
		
		ALWAYS_USE_DEBUGGER => 0 # let subs decide if we jump in the debugger
		ACTIVE => 1
		)
		
	# use the breakpoints
	sub DoSomething
	{
	#DEBUG	
	my %debug_data = 
		(
		  TYPE           => 'VARIABLE'
		, VARIABLE_NAME  => $key
		, VARIABLE_VALUE => $value
		, ...
		) ;
	
	#DEBUG	
	$DB::single = 1 if(Debug::Mixin::IsDebuggerEnabled() && Debug::Mixin::CheckBreakpoint(%debug_data)) ;
	
	# or
	
	if(Debug::Mixin::IsDebuggerEnabled())
		{
		%debug_data = 
			(
			  TYPE           => 'VARIABLE'
			, ...
			) ;
			
		$DB::single = 1 if(Debug::Mixin::CheckBreakpoint(%debug_data, MORE_DATA => 1)) ;
		}
		

=head1 DESCRIPTION

This module help you define breakpoints for your own module or applications making them easier to
debug.

=head1 DOCUMENTATION

Lately,I've been speculating about architectures that would allow us to debug them more easily. Logging, 
aspect oriented, web interface to internals are some examples of techniques already in use.

The perl debugger already allows us to do a lot of tricky testing before displaying a prompt or 
stopping only when certain conditions are met. I believe in making debugging even more  practical
and intelligent.

My theory is simple, actively present data, from your code, and check if a breakpoint matches. This
is, in theory, not very different from smart breakpoints in the debugger except the breakpoints are
defined in files outside the debugger and are part of the module distribution. The place where this 
breakpoints triggers are not defined by the breakpoints but by the code being debugged.

Finding where the breakpoints should be checked is best determined while writing the code though
they can be added later making your module more . This, of course, doesn't stop you
from using the debugger in a normal fashion, with or without the help of these "code called" breakpoints

In your module

	use Debug::Mixin ;
	...
	$DB::single = 1 if(Debug::Mixin::IsDebuggerEnabled() && Debug::Mixin::CheckBreakpoint(%debug_data)) ;

At the cost of a subroutine call, you get checking of breakpoints at a position you deem strategic and the possibility
to stop in the debugger if any of the breakpoints actions flag to stop.

I'd check if the cost has a real impact before trying to reduce it. you could write:

	use Filter::Uncomment GROUPS => [ debug_mixin => ['DM'] ] ;
	use Debug::Mixin ;
	...
	##DM $DB::single = 1 if(Debug::Mixin::IsDebuggerEnabled() && Debug::Mixin::CheckBreakpoint(%debug_data)) ;

You'll now pay only if you are actively using B<Debug::Mixin> to debug your application/modules. The only
cost being the filtration of the code if, and only if, you decide to uncomment. if you don't, the cost is practically zero.

Have I used this in any real project, PBS on CPAN, and it did really help a lot with very complex problems. Mainly
because it let me run debugging very fast but also because the check point were put in the code before I had 
any problems saving me time to find out where I should place them.

=head1 DEBUG SESSION

script Debug::Mixin aware

	perl -d script.pl --argument_loading_plenty_breakpoints

script doesn't have to be aware of modules debugging facilities, only modules using Debug::Mixin have to

	perl -d -MDebug::Mixin='LoadBreakpointsFiles=file' script.pl

	> Using Debug::Mixin banner, use 'dm_help' for Debug::Mixin help.
	
	> dm_help
          dm_subs()                     list and run debugging subs
          dm_load(@files)               load breakpoints files
          
          # all breakpoints functions take a regex
          dm_bp(qr//)                   list breakpoints
	  dm_activate(qr//)             activate breakpoints
	  dm_deactivate(qr//)           deactivate breakpoints
          dm_use_debugger(qr//)         jump in debugger
          dm_dont_use_debugger(qr//)    jump in debugger only if a breakpoint action says to
	
	> run part of the program ...
	
	> Breakpoints display information (eventually interacting with the user)
	
	> stop at a breakpoint, if local commands are available interact with the user, display their documentation

=head1 SUBROUTINES/METHODS

=cut

if(*DB::DB{CODE})
	{
	Output("Debug::Mixin support available, type 'dm_help' for help, or man Debug::Mixin for more help.\n\n") ;
	}
else
	{
	Output("Debug::Mixin banner when debugger is not loaded\n") ;
	}
	
#-------------------------------------------------------------------------------

my $debug_enabled = 1 ;
my %debugger_subs;
tie my %breakpoints, 'Tie::Hash::Indexed' ; ## no critic

#-------------------------------------------------------------------------------

sub import
{

=head2 import

Called for you by Perl

=cut

my ($module_name, $data, @more_data) = @_ ;

my ($package, $file_name, $line) = caller() ;
Output("Debug::Mixin used at '$package, $file_name, $line'\n") ;

#~ use Data::TreeDumper ;
#~ print DumpTree \@_ ;

if(defined $data)
	{
	if('HASH' eq ref $data)
		{
		while( my($key, $value) = each %{$data})
			{
			SetupElement($package, $file_name, $line, $key, $value) ;
			}
		}
	else
		{
		unshift @more_data, $data ;
		for(@more_data)
			{
			SetupElement($package, $file_name, $line, split(/=/sxm, $_)) ;
			}
		}
	}
	
# this module doesnt export any subroutine
#~ Debug::Mixin->export_to_level(1, @_);

#except
if(*DB::DB{CODE})
	{
	
	
	for my $sub
		(
		[\&dm_help, 'dm_help'],
		
		[\&dm_subs , 'dm_subs'],
		
		[\&LoadBreakpointsFiles , 'dm_load'],
		[\&ListBreakpoints , 'dm_bp'],
		
		[\&ActivateBreakpoints, 'dm_activate'],
		[\&DeactivateBreakpoints, 'dm_deactivate'],
		[\&ActivateAlwaysUseDebugger , 'dm_use_debugger'],
		[\&DeactivateAlwaysUseDebugger , 'dm_dont_use_debugger'],
		)
		{
		my ($code, $as) = @{$sub} ;
		
		Sub::Install::reinstall_sub
			({
			code => $code,
			into => 'main',
			as   => $as,
			});
		}
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub SetupElement
{

=head2 SetupElement

Private function

=cut

my ($package, $file_name, $line, $key, $value) = @_ ;

for($key)
	{
	/BANNER/smix and do
		{
		if(*DB::DB{CODE})
			{
			Output("Debug::Mixin loaded for '$value'\n") ;
			}
		next ;
		} ;
		
	/LoadBreakpointsFiles/smx and do
		{
		my $files = 'ARRAY' eq ref $value ? $value : [$value] ;
		
		for my $file (@{$files})
			{
			Output("Loading '$file'\n") ;
			}
		next ;
		} ;
		
	/DEBUGGER_SUBS/smx and do
		{
		croak "Debug::Mixin: DEBUGGER_SUBS must be a list!\n" unless('ARRAY' eq ref $value) ;
		croak "Debug::Mixin: no subroutine defined in DEBUGGER_SUBS!\n" if( @{$value} <= 0) ;
		
		Readonly my $EXPECTED_NUMBER_OF_DEBUGGER_SUB_FIELDS => 5 ;
		
		for my $debugger_sub (@{$value})
			{
			croak "Debug::Mixin: local subroutine must be a hash!\n" unless 'HASH' eq ref $debugger_sub ;
			croak "Debug::Mixin: invalid local subroutine definition!\n" 
				unless $EXPECTED_NUMBER_OF_DEBUGGER_SUB_FIELDS	== keys %{$debugger_sub} ;
			
			my $valid_keys = join('$|^', qw(NAME ALIASES DESCRIPTION HELP SUB)) ; ## no critic
			
			for my $key (keys %{$debugger_sub})
				{
				croak "Debug::Mixin: Unrecognized local subroutine argument '$key'!\n" unless $key =~ /^$valid_keys$/smxo ;
				}
				
			if(*DB::DB{CODE})
				{
				$debugger_subs{$package}{$debugger_sub->{NAME}} = $debugger_sub ;
				
				Sub::Install::reinstall_sub
					({
					code => $debugger_sub->{SUB},
					into => $package,
					as   => $debugger_sub->{NAME},
					});
					
				for my $alias ($debugger_sub->{ALIASES})
					{
					Sub::Install::reinstall_sub
						({
						code => $debugger_sub->{SUB},
						into => $package,
						as   => $alias,
						});
					}
					
				Output("Debug::Mixin registrating debugger sub '${package}::$debugger_sub->{NAME}'\n") ;
				}
			}
			
		next ;
		} ;
		
	croak "Unknown setup element '$key'!\n" ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub EnableDebugger
{

=head2 EnableDebugger

Globally Enables or disables this module.

	Debug::Mixin::EnableDebugger(0) ;
	Debug::Mixin::EnableDebugger(1) ;

=cut

$debug_enabled = shift ;

return($debug_enabled) ;
}

#-------------------------------------------------------------------------------

sub IsDebuggerEnabled
{

=head2 IsDebuggerEnabled

Returns the state of this module.

	my $status = Debug::Mixin::IsDebuggerEnabled() ;

=cut

return($debug_enabled) ;
}

#-------------------------------------------------------------------------------

sub AddBreakpoint ## no critic (Subroutines::RequireArgUnpacking)
{

=head2 AddBreakpoint

	use Debug::Mixin ;
	
	AddBreakpoint
		(
		NAME    =>   'add dependencies'
		
		FILTERS =>
			[
			sub 
				{
				my (%filter) = @_ ;
				$filter{ARGS}{TYPE} eq 'DEPEND' ; # true will enable the actions
				}
			]
			
		ACTIONS =>
			[
			sub 
				{
				my (%filter) = @_ ;
				
				print DumpTree $filter{ARGS}{COMPLEX_ELEMENT} ;
				
				return JUMP_TO_DEBUGGER # want to jump into debugger
				}
			]
			
		DEBUGGER_SUBS =>
			[
				{
				NAME        => 'CheckDependencyMatrix',
				ALIASES     => [qw(dm_cdm cdm)],
				DESCRIPTION => "a short description of what this sub is for",
				HELP        => "a long, possibly multi line description displayed"
						. "when the user needs it",
				SUB         => sub{},
				}
			]
			
		LOCAL_STORAGE => {}
		
		ALWAYS_USE_DEBUGGER => 0 # let subs decide if we jump in the debugger
		ACTIVE => 1
		)


=head2 Breakpoint elements

=over 2

=item * NAME

The name of the breakpoint, you can remove and otherwise manipulate breakpoints by name.

=item * FILTERS

Used to enable or disable all the actions with a single check. FILTERS is a list of sub references. The
references are passed the argument you pass to L<CheckBreakpoints> and :

=over 2

=item * DEBUG_MIXIN_BREAKPOINT

A reference to the breakpoint.

=item * DEBUG_MIXIN_CALLED_AT

a hash containing the file and line where L<CheckBreakpoints> was called.

=back

=item * ACTIONS

B<ACTIONS> is a list of sub references. All the subs are run. All debugging functionality
(ex: activating or adding breakpoints) are available within the subs.

=item * DEBUGGER_SUBS

List of functions available, at the time the breakpoint matches, when running under the debugger.
Debug::Mixin will present you with the list of local functions and allow you to run any of the functions.

each entry must have follow the following format

	{
	NAME        => 'CheckDependencyMatrix',
	ALIASES     => [qw(dm_cdm cdm)],
	DESCRIPTION => "a short description of what this sub is for",
	HELP        => "a long, possibly multi line description displayed"
			. "when the user needs it",
	SUB         => sub{},
	}

=item * ALWAYS_USE_DEBUGGER

If the breakpoint is active, L<CheckBreakpoints> will always return true.

=item * ACTIVE

The breakpoint actions will only be called if B<ACTIVE> is set.

=item * LOCAL_STORAGE

A user storage area within the breakpoint. You can store and manipulate it as you wish. You must use
this area as Debug::Mixin only allows certain fields in a breakpoint.

This item can be manipulated through the breakpoint reference passed to filters and actions.

=back

A warning is displayed if you override an existing breakpoint. A breakpoint creation history is kept.

=cut

croak 'AddBreakpoint: odd number of arguments!' if @_ % 2 ;

my (%breakpoint) = @_ ;

CheckBreakPointDefinitions(\%breakpoint) ;

my ($package, $file_name, $line) = caller() ;

unless (exists $breakpoints{$breakpoint{NAME}})
	{
	$breakpoints{$breakpoint{NAME}} = \%breakpoint ;
	}
else
	{
	carp ("Redefining breakpoint '$breakpoint{NAME}' at '$file_name:$line'.\n")  ;
	
	#keep history
	my $at = $breakpoints{$breakpoint{NAME}}{AT} ;
	$breakpoints{$breakpoint{NAME}} = \%breakpoint ;
	
	$breakpoints{$breakpoint{NAME}}{AT} = $at ;
	}

push @{$breakpoints{$breakpoint{NAME}}{AT}}, {FILE => $file_name, LINE => $line, PACKAGE => $package} ;

return(1) ;
}

#----------------------------------------------------------------------

sub CheckBreakPointDefinitions
{## no critic (ProhibitExcessComplexity)

=head2 CheckBreakPointDefinitions

Checks the validity of the user supplied breakpoint definitions. Croaks on error.

=cut

my ($breakpoint) = @_ ;

my $valid_keys = join('$|^', qw(NAME FILTERS ACTIONS DEBUGGER_SUBS LOCAL_STORAGE ALWAYS_USE_DEBUGGER ACTIVE)) ; ## no critic

for my $key (keys %{$breakpoint})
	{
	croak "AddBreakpoint: Unrecognized argument '$key'!\n" unless $key =~ /^$valid_keys$/smox ;
	}

croak "AddBreakpoint: Missing NAME!\n" unless exists $breakpoint->{NAME} && defined $breakpoint->{NAME} ;
croak "AddBreakpoint: NAME must be a scalar!\n" unless $EMPTY_STRING eq ref $breakpoint->{NAME} ;

if(exists $breakpoint->{ACTIONS})
	{
	croak "AddBreakpoint: ACTIONS must be a list of subs!\n" unless 'ARRAY' eq ref $breakpoint->{ACTIONS} ;
	croak "AddBreakpoint: no actions defined in ACTIONS!\n" if  @{$breakpoint->{ACTIONS}} <= 0 ;
	croak "AddBreakpoint: actions is not a sub reference!\n"  if any {'CODE' ne ref $_} @{$breakpoint->{ACTIONS}} ;
	}

if(exists  $breakpoint->{FILTERS})
	{
	croak "AddBreakpoint: FILTERS must be an array!\n" unless 'ARRAY' eq ref $breakpoint->{FILTERS} ;
	croak "AddBreakpoint: no filters defined in FILTERS!\n" if @{$breakpoint->{FILTERS}} <= 0 ;
	croak "AddBreakpoint: filter is not a code ref!\n"  if any {'CODE' ne ref $_} @{$breakpoint->{FILTERS}} ;
	}
	
unless
	(
	exists $breakpoint->{ACTIONS} 
	||
	(exists $breakpoint->{FILTERS} && exists $breakpoint->{ALWAYS_USE_DEBUGGER} && $breakpoint->{ALWAYS_USE_DEBUGGER} == 1)
	)
	{
	croak "AddBreakpoint: Missing ACTIONS or (FILTERS + ALWAYS_USE_DEBUGGER)!\n" 
	}

if(exists $breakpoint->{DEBUGGER_SUBS})
	{
	croak "AddBreakpoint: DEBUGGER_SUBS must be a list!\n" unless 'ARRAY' eq ref $breakpoint->{DEBUGGER_SUBS} ;
	croak "AddBreakpoint: no subroutine defined in DEBUGGER_SUBS!\n" if @{$breakpoint->{DEBUGGER_SUBS}} <= 0 ;
	
	Readonly my $EXPECTED_NUMBER_OF_DEBUGGER_SUB_FIELDS => 4 ;
	
	for my $debugger_sub (@{$breakpoint->{DEBUGGER_SUBS}})
		{
		croak "AddBreakpoint: local subroutine must be a hash!\n" unless 'HASH' eq ref $debugger_sub ;
		croak "AddBreakpoint: invalid local subroutine definition!\n" 
			unless  $EXPECTED_NUMBER_OF_DEBUGGER_SUB_FIELDS == keys %{$debugger_sub} ;
		
		my $valid_function_keys = join('$|^', qw(NAME DESCRIPTION HELP SUB)) ; ## no critic
		
		for my $key (keys %{$debugger_sub})
			{
			croak "AddBreakpoint: Unrecognized local subroutine argument '$key'!\n" unless $key =~ /^$valid_function_keys$/smox ;
			}
		}
	}
	
croak "AddBreakpoint: ALWAYS_USE_DEBUGGER must be a scalar!\n" if exists $breakpoint->{ALWAYS_USE_DEBUGGER}&& $EMPTY_STRING ne ref $breakpoint->{ALWAYS_USE_DEBUGGER} ;
croak "AddBreakpoint: ACTIVE must be a scalar!\n" if exists $breakpoint->{ACTIVE}&& $EMPTY_STRING ne  ref $breakpoint->{ACTIVE} ;

return ;
}

#----------------------------------------------------------------------

sub LoadBreakpointsFiles
{

=head2 LoadBreakpointsFiles

Evaluates a perl script. The main purpose of the script is to define breakpoints but the script
can also query Debug::Mixin and change existing breakpoints or run any perl code deemed fit.

Croaks on error, return(1) on success.

=cut

my (@files) = @_ ; # can contains breakpoint definitions

for my $file (@files)
	{
	if($file ne $EMPTY_STRING)
		{
		unless (my $return = do $file ) 
			{
			croak "couldn't parse '$file': $EVAL_ERROR" if $EVAL_ERROR;
			croak "couldn't do '$file': $OS_ERROR"      unless defined $return;
			#~ croak "couldn't run '$file'"                unless $return;
			}
		}
	}
	
return(1) ;
}

#----------------------------------------------------------------------

sub RemoveBreakpoints
{

=head2 RemoveBreakpoints

Removes one or more breakpoint matching the name regex passed as argument. A warning is displayed
for each removed breakpoint.

	Debug::Mixin::RemoveBreakpoints(qr/dependencies/) ;

Returns the number of removed breakpoints.

=cut

my ($breakpoint_regex) = @_ ;
$breakpoint_regex ||= q{.} ;

my $removed_breakpoints = 0 ;#bp local subs

for my $breakpoint_name (sort keys %breakpoints)
	{
	if($breakpoint_name =~ $breakpoint_regex)
		{
		carp("Debug::Mixin: Breakpoint '$breakpoint_name' removed.\n") ;
		delete $breakpoints{$breakpoint_name} ;
		$removed_breakpoints++ ;
		}
	}

return($removed_breakpoints) ;
}

#----------------------------------------------------------------------

sub RemoveAllBreakpoints
{

=head2 RemoveAllBreakpoints

Removes all breakpoints. No message is displayed.

	Debug::Mixin::RemoveAllBreakpoints();

=cut

%breakpoints = () ;

return(1) ;
}

#----------------------------------------------------------------------

sub ListDebuggerSubs
{

=head2 ListDebuggerSubs

List all the debugger subs registered by modules loading Debug::Mixin on STDOUT.

=cut

my (@packages) = @_ ;

unless(@packages)
	{
	@packages = keys %debugger_subs ;
	}
	
for my $package(@packages)
	{
	Output(DumpTree($debugger_subs{$package}, "$package:")) ;
	}

return(1) ;
}

#----------------------------------------------------------------------

sub ListBreakpoints
{

=head2 ListBreakpoints

List, on STDOUT, all the breakpoints matching the name regex passed as argument.

=cut

my ($breakpoint_regex) = @_ ;
$breakpoint_regex = qr/./sxm unless defined $breakpoint_regex ;

for my $breakpoint_name (sort keys %breakpoints)
	{
	if($breakpoint_name =~ $breakpoint_regex)
		{
		Output(DumpTree($breakpoints{$breakpoint_name}, "$breakpoint_name:")) ;
		}
	}

return(1) ;
}

#----------------------------------------------------------------------

sub GetBreakpoints
{

=head2 GetBreakpoints

Returns a reference to all the breakpoints. Elements are returned in the insertion order.

Use this only if you know what you are doing.

=cut

return(\%breakpoints) ;
}

#----------------------------------------------------------------------

sub ActivateBreakpoints
{

=head2 ActivateBreakpoints

Activate all the breakpoints matching the name regex passed as argument.

Only active breakpoints are checked by Debug::Mixin.

=cut

my (@breakpoint_regexes) = @_ ;
push @breakpoint_regexes, q{.} unless @breakpoint_regexes ;

my $activated_breakpoints = 0 ;

for my $breakpoint_name (sort keys %breakpoints)
	{
	for my $breakpoint_regex (@breakpoint_regexes)
		{
		next unless $breakpoint_name =~ $breakpoint_regex ;
		
		$breakpoints{$breakpoint_name}{ACTIVE} = 1 ;
		carp("Breakpoint '$breakpoint_name' activated. \n") ;#bp local subs
		
		$activated_breakpoints++ ;
		}
	}

return($activated_breakpoints) ;
}

#----------------------------------------------------------------------

sub DeactivateBreakpoints
{

=head2 DeactivateBreakpoints

Deactivate all the breakpoints matching the name regex passed as argument.

Only active breakpoints are checked by when you call I<CheckBreakpoints>.

=cut

my (@breakpoint_regexes) = @_ ;
push @breakpoint_regexes, q{.} unless @breakpoint_regexes ;

my $deactivated_breakpoints = 0 ;

for my $breakpoint_name (sort keys %breakpoints)
	{
	for my $breakpoint_regex (@breakpoint_regexes)
		{
		next unless $breakpoint_name =~ $breakpoint_regex ;
		
		$breakpoints{$breakpoint_name}{ACTIVE} = 0 ;
		carp("Breakpoint '$breakpoint_name' deactivated. \n") ;
		}
	}

return($deactivated_breakpoints) ;
}

#----------------------------------------------------------------------

sub ActivateAlwaysUseDebugger
{

=head2 ActivateAlwaysUseDebugger

Sets all breakpoints matching the name regex passed as argument to always jumps to the perl debugger.

=cut

my (@breakpoint_regexes) = @_ ;
my $always_use_debugger_breakpoints = 0 ;

for my $breakpoint_name (sort keys %breakpoints)
	{
	for my $breakpoint_regex (@breakpoint_regexes)
		{
		next unless $breakpoint_name =~ $breakpoint_regex ;
		
		$breakpoints{$breakpoint_name}{ALWAYS_USE_DEBUGGER} = 1 ;
		carp("Breakpoint '$breakpoint_name' will always activate the perl debugger.\n") ;
		
		$always_use_debugger_breakpoints++ ;
		}
	}

return($always_use_debugger_breakpoints) ;
}

#----------------------------------------------------------------------

sub DeactivateAlwaysUseDebugger
{

=head2 DeactivateAlwaysUseDebugger

Sets all breakpoints matching the name regex passed as argument, to never jumps to the perl debugger.

=cut

my (@breakpoint_regexes) = @_ ;
my $never_use_debugger_breakpoints = 0 ;

for my $breakpoint_name (sort keys %breakpoints)
	{
	for my $breakpoint_regex (@breakpoint_regexes)
		{
		next unless $breakpoint_name =~ $breakpoint_regex ;
		
		$breakpoints{$breakpoint_name}{ALWAYS_USE_DEBUGGER} = 0 ;
		carp("Breakpoint '$breakpoint_name' will NOT always activate the perl debugger. \n") ;
		
		$never_use_debugger_breakpoints++ ;
		}
	}

return($never_use_debugger_breakpoints) ;
}

#----------------------------------------------------------------------

sub CheckBreakpoints ## no critic (Subroutines::RequireArgUnpacking)
{

=head2 CheckBreakpoints

Check a user state against all registered breakpoints. Returned value tells caller if it 
should jump into the debugger.

	if(Debug::Mixin::IsDebuggerEnabled())
		{#bp local subs


		%debug_data = 
			(
			  # user data passed to the breakpoint actions
			  TYPE           => '...'
			, COMMENT        => '...'
			, ...
			) ;
			
		$DB::single = 1 if(Debug::Mixin::CheckBreakpoint(%debug_data)) ;
		}


=cut
	
return(0) unless $debug_enabled ;

my (%user_state) = @_ ;

my $use_debugger = 0 ;

my ($package, $file_name, $line) = caller() ;

for my $breakpoint (values %breakpoints)
	{
	next unless $breakpoint->{ACTIVE} ;
	
	my $breakpoint_matches = 0 ;
	
	if(exists $breakpoint->{FILTERS})
		{
		my $filter_index = 0 ;
		
		for my $filter ( @{$breakpoint->{FILTERS}})
			{
			eval
				{
				$breakpoint_matches+=
					$filter->
						(
						%user_state,
						DEBUG_MIXIN_BREAKPOINT => $breakpoint,
						DEBUG_MIXIN_CALLED_AT =>  {FILE => $file_name,LINE => $line}
						) ;
				} ;
				
			if($EVAL_ERROR)
				{
				my $original_exception = $EVAL_ERROR ;
				chomp $original_exception ;
				
				my $error_message = 
						 "CheckBreakpoints: Caught exception while running breakpoint filter!\n"
						. DumpTree
							({
							BREAKPOINT => $breakpoint,
							CALLED_AT =>  {FILE => $file_name,LINE => $line}
							})
						. "Action # $filter_index\n"
						. "Original exception: '$original_exception'\n";
						
				if(*DB::DB{CODE})
					{
					carp $error_message ;
					$DB::single = 1 ; ## no critic
					}
				else
					{
					croak $error_message ;
					}
				}
				
			$filter_index++ ;
			}
		}
	else
		{
		$breakpoint_matches++ ;
		}
		
	$use_debugger++ if $breakpoint->{ALWAYS_USE_DEBUGGER} ;
	
	if($breakpoint_matches)
		{
		$breakpoint->{MATCHED}++ ;
		
		my $action_index = 0 ;
		for my $action (@{$breakpoint->{ACTIONS}})
			{
			eval
				{
				my $result = $action->
						(
						%user_state,
						DEBUG_MIXIN_BREAKPOINT => $breakpoint,
						DEBUG_MIXIN_CALLED_AT =>  {FILE => $file_name,LINE => $line}
						) ;
									
				$use_debugger += $result || 0 ;
				} ;
				
			if($EVAL_ERROR)
				{
				my $original_exception = $EVAL_ERROR ;
				chomp $original_exception ;
				
				my $error_message = 
						 "CheckBreakpoints: Caught exception while running breakpoint action!\n"
						. DumpTree
							({
							BREAKPOINT => $breakpoint,
							CALLED_AT =>  {FILE => $file_name,LINE => $line}
							})
						. "Action # $action_index\n"
						. "Original exception: '$original_exception'\n";
						
				if(*DB::DB{CODE})
					{
					carp $error_message ;
					$DB::single = 1 ; ## no critic
					}
				else
					{
					croak $error_message ;
					}
				}
				
			$action_index++ ;
			}
			
		if(*DB::DB{CODE} && exists $breakpoint->{DEBUGGER_SUBS})
			{
			HandleBreakpointSubInteraction($breakpoint, $file_name, $line, \%user_state) ;
			}
		}
	}

return($use_debugger) ;
}

#-------------------------------------------------------------------------------

sub HandleBreakpointSubInteraction
{

=head2 HandleBreakpointSubInteraction

Private subroutine handling user interaction in a debugger session.

=cut

my ($breakpoint, $file_name, $line, $user_state)  = @_ ;
my $choice = $EMPTY_STRING ;

do 
	{
	my $header = "Debug::Mixin: Available subs at breakpoint '$breakpoint->{NAME}' ($breakpoint->{MATCHED}):" ;
	my $separator = q{-} x length $header ;
	Output("$separator\n$header\n$separator\n") ;

	my $index = 0 ;

	my $max_length = 0 ;
	for my $sub (@{$breakpoint->{DEBUGGER_SUBS}})
		{
		$max_length = length($sub->{NAME}) if length($sub->{NAME}) > $max_length ;
		}

	for my $sub (@{$breakpoint->{DEBUGGER_SUBS}})
		{
		Output(sprintf("   #%2d %${max_length}s => $sub->{DESCRIPTION}\n", $index, $sub->{NAME})) ;
		$index++ ;
		}
		
	Output("\n'#' to run sub, 'd #' for a long descriptions of the sub or 'c' to continue.\n") ;
	Output(q{>}) ;
	
	$choice = <> ;
	chomp($choice) ;
	
	for($choice)
		{
		/^[0-9]+$/smx and do
			{
			if($choice < @{$breakpoint->{DEBUGGER_SUBS}})
				{
				$breakpoint->{DEBUGGER_SUBS}[$choice]{SUB}->
					(
					%{$user_state},
					DEBUG_MIXIN_BREAKPOINT => $breakpoint,
					DEBUG_MIXIN_CALLED_AT =>  {FILE => $file_name,LINE => $line}
					) ;
				}
			#else
				# invalid input re-query user

			last ;
			} ;
			
		/^d ([0-9]+)$/smx and do
			{
			my $sub_index = $1 ; ## no critic
			
			if($sub_index  < @{$breakpoint->{DEBUGGER_SUBS}})
				{
				my $sub =  $breakpoint->{DEBUGGER_SUBS}[$sub_index] ;
				
				my $sub_header = "$sub->{NAME}:" ;
				my $sub_separator = q{-} x length($sub_header) ;
				
				Output("$sub_header\n$sub_separator\n$sub->{HELP}\n\n") ;
				}
				
			last ;
			}
		}
	}
while($choice ne 'c') ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub dm_help
{

=head2 dm_help

Displays the commands made available by B<Debug::Mixin> in the debugger.

=cut

Output(<<'EOC') ;
	dm_subs                     list and run debugging subs
	
	dm_load @files              load breakpoints files

	# all breakpoints functions take a optional regex
	
	dm_bp                   list breakpoints
	dm_activate             activate breakpoints
	dm_deactivate           deactivate breakpoints
	dm_use_debugger         jump in debugger
	dm_dont_use_debugger    jump in debugger only if a breakpoint action says to

EOC

return(1) ;
} 

#-------------------------------------------------------------------------------

sub dm_subs
{

=head2 dm_subs

List all the available debugging subs and interacts with the user to run them. 

=cut

my $choice = $EMPTY_STRING ;

do 
	{
	my $header = 'Debug::Mixin: Available subs:' ;
	my $separator = q{-} x length $header ;
	Output("$separator\n$header\n$separator\n") ;
	
	my $index = 0 ;
	my $max_length = 0 ;
	my @subs = () ;
	
	for my $package (keys %debugger_subs)
		{
		Output("$package:\n") ;
		
		for my $sub (values %{$debugger_subs{$package}})
			{
			push @subs, $sub ;
			
			Output(sprintf("   #%2d $sub->{NAME} => $sub->{DESCRIPTION}\n", $index)) ;
			$index++ ;
			}
			
		Output("\n") ;
		}
		
	Output("\n'#' to run sub, 'd #' for a long descriptions of the sub or 'c' to continue.\n") ;
	Output(q{>}) ;
	
	$choice = <> ;
	chomp($choice) ;
	
	for($choice)
		{
		/^[0-9]+$/smx and do
			{
			if($choice < @subs)
				{
				$subs[$choice]{SUB}->() ;
				}
			#else
				# invalid input re-query user
				
			last ;
			} ;
			
		/^d ([0-9]+)$/smx and do
			{
			my $sub_index = $1 ; ## no critic
			
			if($sub_index  < @subs)
				{
				my $sub =  $subs[$sub_index] ;
				
				my $sub_header = "$sub->{NAME}:" ;
				my $sub_separator = q{-} x length($sub_header) ;
				
				Output("$sub_header\n$sub_separator\n$sub->{HELP}\n\n") ;
				}
				
			last ;
			} ;
			
		}
	}
while($choice ne 'c') ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub Output ## no critic (Subroutines::RequireArgUnpacking)
{

=head2 Output

Prints the passed arguments 

=cut

print(@_) or die "Can't output!\n" ;

return ;
}

#-------------------------------------------------------------------------------
1 ;

=head1 TO DO

More test, testing the module through the perl debugger's automation.

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Debug::Mixin

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Debug-Mixin>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-my $storage_ref = debug-mixin@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Debug-Mixin>

=back

=head1 SEE ALSO

L<Filter::Uncomment>

=cut
