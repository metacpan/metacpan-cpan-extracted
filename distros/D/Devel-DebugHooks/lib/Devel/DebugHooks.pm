package Devel::DebugHooks;

BEGIN {
	if( $DB::options{ w } ) { require 'warnings.pm';  'warnings'->import(); }
	if( $DB::options{ s } ) { require 'strict.pm';    'strict'->import();   }
	if( $options{ d } ) { require 'Data/Dump.pm'; 'Data::Dump'->import( 'pp'); }
}


our $VERSION =  '0.05';

=head1 NAME

C<Devel::DebugHooks> - Hooks for perl debugger

=head1 SYNOPSIS

 perl -d:DebugHooks::Terminal script.pl

 ## If you want to debug remotely you required additionally install IO::Async
 # on remote
 perl -d:DebugHooks::Server script.pl
 # on local
 ./dclient.pl 1.2.3.4 9000

=cut


# We should init $DB::dbg as soon as possible, because if trace_subs/load are
# enabled at compile time (at the BEGIN block) the DB:: module will make call
# to $dbg->trace_subs/load. Also these subs should be declared before the
# 'use Devel::DebugHooks' in other case you will get:
# 'Call to undefined sub YourModule::trace_subs/load is made...'
# That is because perl internals make calls to DB::* as soon as the subs in it
# are compiled even whole file is not processed yet.
# Also do not forget to 'push @ISA, "YourModule"' if you set these DB:: options at
# compile time: trace_load, trace_subs,
BEGIN {
	unless( defined $DB::dbg ) {
		my $level =  0;
		while( my $frame =  caller($level++) ) {
			$DB::dbg =  $frame   if $frame =~ /^Devel::/;
		}

		$DB::dbg //=  __PACKAGE__;

		# ISSUE: We can not make 'main' package as descendant of 'Devel::DebugHooks'
		# because of broken info from 'caller', so I restrict pkg_names to 'Devel::'
		# TODO: Ask #p5p about that 'caller' shows strange file:line for (eval)
		# https://rt.perl.org/Public/Bug/Display.html?id=127083
	}
}



sub pop_frame {
	#NOTICE: We will fall into infinite loop if something dies inside this sub
	#because this sub is called when flow run out of scope.
	#TODO: Put this code into eval block

	my $stack =  DB::state( 'stack' );
	my $last =  pop @$stack;
	DB::print_state( "POP  FRAME <<<< ",
		"  --  $last->{ sub }\@". @$stack ."\n"
		."    $last->{ file }:$last->{ line }\n\n"
	) if DB::state( 'ddd' );

	if( @{ DB::state( 'stack' ) } ) {
		# Restore $DB::single for upper frame
		DB::state( 'single', DB::state( 'single' ) );
	} else {
		# Something nasty happened at &push_frame, because of we are at
		# &pop_frame already but not "push @{ state( 'stack' ) }" done yet
		print $DB::OUT "Error happen while &pop_frame. Pay attention to this!\n";
		$DB::single =  0;
	}
}



{
	my $handler =  DB::reg( 'pop_frame', 'DebugHooks' );
	$$handler->{ context } =  $DB::dbg;
	$$handler->{ code }    =  \&pop_frame;
}




sub test {
	1;
	2;
}



sub push_frame {
	{ # these lines exists for testing purpose
		no warnings 'void';
		test();
		3;
	}

	shift; #Turf event context
	my $sub =  shift;
	DB::print_state( "PUSH FRAME $_[0] >>>>  ", "  --  $sub\n" )   if DB::state( 'ddd' );

	if( $_[0] ne 'G' ) {
		# http://stackoverflow.com/questions/34595192/how-to-fix-the-dbgoto-frame
		# WORKAROUND: for broken frame. Here we are trying to be closer to goto call
		# Most actual info we get when we trace script step-by-step at this case
		# those vars have sharp last opcode location.
		if( !DB::state( 'eval' ) ) {
			#TODO: If $DB::single == 1 we can skip this because cursor is updated at DB::DB
			my( $p, $f, $l ) =  caller 5;
			DB::state( 'package', $p );
			DB::state( 'file',    $f );
			DB::state( 'line',    $l );
			DB::print_state( "", sprintf "\n    cursor(PF) => %s, %s, %s\n" ,$p ,$f, $l )   if DB::state( 'ddd' );
		}

		my $stack =  DB::state( 'stack' );
		my $frame =  {()
			# Until we stop at a callee last known cursor position is the caller position
			,package     =>  $stack->[-1]{ package }
			,file        =>  $stack->[-1]{ file    }
			,line        =>  $stack->[-1]{ line    }
			,single      =>  $stack->[-1]{ single  }
			,sub         =>  $sub
			,goto_frames =>  []
			,type        =>  $_[0]
		};


		DB::emit( 'frame', $frame );

		#TODO: Now we push always. Q: How to skip coresopnding &pop_frame?
		# Think about this feature: if( $confirm ) {
		push @{ $stack }, $frame;
	}
	else {
		push @{ DB::state( 'goto_frames' ) },
			[ DB::state( 'package' ), DB::state( 'file' ), DB::state( 'line' ), $sub, $_[0] ]
	}


	DB::emit( 'call', $sub );
	1;
}



{
	my $handler =  DB::reg( 'push_frame', 'DebugHooks' );
	$$handler->{ context } =  $DB::dbg;
	$$handler->{ code }    =  \&push_frame;
}



# NOTICE: We do not inherit DB:: interface, we use it
sub import {
	if( $_[0] eq 'Devel::DebugHooks' ) {
		shift;
		for my $module ( @_ ) {
			my( $package, $args ) =  $module =~ m/^([^=]+)=?(.*)$/;
			$DB::dbg =  "Devel::DebugHooks::$package";
			$package  =~ s/::/\//;
			require "Devel/DebugHooks/$package.pm";
			$DB::dbg->import( split ':', $args );
		}
	}
	else {
		DB::import( @_ );
	}
	# shift->SUPER::import( @_ );
}



package
	x;

sub x { # This is 'invader' :)
	# When we returns from this sub the $DB::single is restored at 'DB::sub_returns'
	DB::state( 'stack' )->[-1]{ single } =  1   if !@_  ||  $_[0];
	# TODO: Allow to disable trap
}

# NOTICE: x::x; does not work at the end of sub

package
	X;
sub X {
	local $^D |= (1<<30);
	DB::state( 'stack' )->[-1]{ single } =  1;
	DB::state( 'single', 1 );
	1;
}



package DB::Error;
use overload bool => sub {1}, '""' => sub { shift->error }, fallback => 1;

sub error {
	return shift->{ error };
}


package DB;

# In theory this may break user's code because this usage cause dependencies are loaded
# in different order under debugger
use Scope::Cleanup qw/ establish_cleanup /;
use Sub::Metadata qw/ mutate_sub_is_debuggable /;
use List::Util;

BEGIN {
	# https://metacpan.org/pod/release/PEVANS/Scalar-List-Utils-1.27/lib/List/Util.pm#SUGGESTED-ADDITIONS
	# Perl <=5.18 have List::Utils 1.27 which have not next functions:
	$List::Util::VERSION <= 1.27  &&  eval '
		sub List::Util::any(&@) { my $sub =  shift;	$sub->() && return 1 for @_; 0 }
		sub List::Util::all(&@) { my $sub =  shift; $sub->() || return 0 for @_; 1 }
	';
}



## Utility subs
sub orig_frames {
	BEGIN{ 'warnings'->unimport( 'uninitialized' )   if $DB::options{ w } }
	my( $count, $warn ) =  @_;
	$count //=  -1; # infinite

	my $lvl =  0;
	# $x  &&  $y = 3 in this case '=' op precedence should be higher then &&
	while( $count--  &&  (my @frame =  caller( $lvl++ )) ) {
		$_ =  "@frame[0..3,5]\n";
		print $DB::OUT $_   unless $warn;
		warn $_             if $warn;
	}

	print $DB::OUT "\n"   unless $warn;
}


# This sub is called twice: at compile time and before run time of 'main' package
sub applyOptions {
	# Q: is warn expected when $DB::trace == undef?
	$DB::trace =  $DB::options{ trace_line } || 0
		if defined $DB::options{ trace_line };

	$^P &= ~0x20   if $DB::options{ NonStop };
	DB::state( 'single', 1 )   if $DB::options{ Stop };
}



sub print_state {
	my( $before, $after ) =  @_;

	local $DB::state->[ -1 ]{ ddd };

	my( undef, $f, $l ) =  caller;
	print $DB::OUT
		$before
		."DB::state: l:" .@$DB::state ." d:" .(DB::state('inDB')//0)
		." s:$DB::single t:$DB::trace"
		."  $f:$l"
		.($after // "\n")
	;
}



sub log_access {
	my( $debug, $context, $hash, $name, $value ) =  @_;

	my $old_value =  $hash->{ $name } // 'undef';
	my $new_value =  '';
	if( @_ >= 5 ) {
		$new_value =  ' -> '. ($value//'undef');
		defined $value
			? $hash->{ $name } =  $value
			: delete $hash->{ $name };
	}

	if( $debug  &&  ( @_ >= 5 || $debug >= 2 ) ) {
		# We are not interested at address of value only its state
		# Also this makes life happy when we compare diff for two debugger output
		$old_value =  ref $old_value ? ref $old_value : $old_value;
		$new_value =  ref $new_value ? ref $new_value : $new_value;
		print $DB::OUT " ${context}::$name: $old_value$new_value\n";
	}


	return $hash->{ $name };
}



sub int_vrbl {
	my( $self, $name, $value, $preserve_frame ) =  @_;

	#TODO: do not affect current debugger state if we are { inDB } mode
	if( @_ >= 3 ) {
		no strict "refs";
		if( $self->{ debug } ) {
			print $DB::OUT " ( DB::$name: ${ \"DB::$name\" } -> $value )";
			$self->{ debug }++   if $preserve_frame;
		}

		${ "DB::$name" } =  $value;
	}


	return frm_vrbl( $self, $name, (@_>=3 && !$preserve_frame ? $value : ()) );
}



sub dbg_vrbl {
	my $self =  shift;

	my $dbg =  $self->{ instance } // $DB::state->[-1];

	return log_access( $self->{ debug }, 'DBG', $dbg, @_ );
}



sub frm_vrbl {
	my $self =  shift;

	my $frame;
	{
		local $self->{ debug };
		$frame =  dbg_vrbl( $self, 'stack' )->[ -1 ];
	}

	return log_access( $self->{ debug }, 'FRM', $frame, @_ );
}



mutate_sub_is_debuggable( \&state, 0 );
sub state {
	return   unless $DB::state  &&  @$DB::state;

	my( $name, $value ) =  @_;

	# Do not debug access into 'ddd' flag
	my $debug =  $name ne 'ddd'  &&  $DB::state->[ -1 ]{ ddd } // 0;
	# If we run debugger command do not trace access to debugger state
	$debug -=  3   if $DB::state->[ -1 ]{ cmd }  &&  $name ne 'cmd';
	$debug  =  0   if $debug < 0;

	# Show full stack only when verbose mode ON and only before changes
	# or before implicit changes: when debugger command take whole 'stack'
	# and manipulate data directly
	if( $debug  &&  (($debug >= 3  &&  @_ >= 2)  ||  $name eq 'stack' ) ) {
		print_state "\n    ";

		for( @$DB::state ) {
			print $DB::OUT "    ***\n";
			for my $option ( sort keys %$_ ) {
				my $value =  $_->{ $option };
				$value =  ref $value ? ref $value : $value;
				print $DB::OUT '    ', $option, " =  $value\n";
			}
			my $CNT =  5;
			for( @{ $_->{ stack } } ) {
				last   if $CNT-- == 0;
				print $DB::OUT "    ";
				for my $key ( sort keys %$_ ) {
					my $value =  $_->{ $key };
					$value =  ref $value ? ref $value : $value;
					print $DB::OUT "  $key => $value;";
				}
				print $DB::OUT "\n";
			}
		}

		print $DB::OUT '    ', '-'x20 ."\n";
	}

	# Force access into last instance if we are in debugger
	my $inDB  =  $DB::state->[ -1 ]{ inDB  };
	my $level =  -1;
	$level =  -2   if @$DB::state >= 2  &&  !$inDB  &&  $name ne 'inDB';
	my $instance =  $DB::state->[ $level ];

	if( $debug && ( @_ >= 2 || $debug >= 2 ) ) {
		my($file, $line) =  (caller 0)[1,2];
		$file =~ s'.*?([^/]+)$'$1'e;
			print $DB::OUT "    " .-$level ." $file:$line: ";
	}

	unless( $instance ) {
		my($file, $line) =  (caller 0)[1,2];
		$file =~ s'.*?([^/]+)$'$1'e;
		print $DB::OUT "!!!!!!    No debugger at level: $level at $file:$line<<<<<<<<<\n";
		return;
	}



	if( $name eq 'instance' ) {
		print $DB::OUT " INT::instance\n"   if $debug && ( @_ >= 2 || $debug >= 2 );
		return $instance;
	}

	$name =  '*'   unless exists $DB::variables->{ $name };
	return $DB::variables->{ $name }({()
			,debug    =>  $debug
			,instance =>  $instance
		}
		,@_
	);
}



sub _ddd {
	return $DB::state->[ -1 ]{ ddd };
}



sub new {
	my $ddd =  DB::state( 'ddd' );

	# NOTICE: After creating new debugger instance we are in debugger yet
	# So we set { inDB } flag. It allows us safely initialize new debugger
	# instance through &DB::state ( see &DB::state ). We do not do that directly
	# to spy which state and how it is changed when { ddd } is turned on
	my $dbg_instance =  bless { inDB => 1, stack =>  [ {()
		,goto_frames =>  []
		# ,type => 'D'
	} ], @_ }, $DB::dbg;
	push @$DB::state, $dbg_instance;

	# New debugger instance should have same { ddd } flag
	# DB::state( 'ddd', $ddd )   if defined $ddd;

	if( @$DB::state > 1 ) {
		my @events =  grep{ /^on_/ } keys %{ $DB::state->[-2] };
		@{ $DB::state->[-1] }{ @events } =  @{ $DB::state->[-2] }{ @events };
	}

	print $DB::OUT "\nIN DEBUGGER  >>>>>>>>>>>>>>>>>>>>>>\n\n"
		if DB::state( 'ddd' );

	my $self;
}



sub DESTROY {
	# Clear { dd } flag to prevent debugging for next command
	DB::state( 'dd', undef );
	DB::state( 'debug', undef );

	print $DB::OUT "\nOUT DEBUGGER  <<<<<<<<<<<<<<<<<<<<<<\n\n"
		if _ddd;
	pop @$DB::state;
	# NOTICE: previous frame is always have { inDB } flag on because there is
	# no any way to run new debugger instance as from debugger
	# (See &DB::scall and assert { inDB } check)
}



# Used perl internal variables:
# ${ ::_<filename }  # maintained at 'file' and 'sources'
# @{ ::_<filename }  # maintained at 'source' and 'can_break'
# %{ ::_<filename }  # maintained at 'traps'
# $DB::single
# $DB::signal
# $DB::trace
# $DB::sub   # NOTICE: this maybe the reference to sub, not just the name of it
# %DB::sub   # maintained at 'location' and 'subs'
# %DB::postponed
# @DB::args  # maintained at 'frames'

# Perl sets up $DB::single to 1 after the 'script.pl' is compiled, so we are able
# to debug it from first OP. We can disable this feature through NonStop option.

our $dbg;            # debugger object/class
# our $package;        # current package
# our $file;           # current file
# our $line;           # current line number
# our @goto_frames;    # save sequence of places where nested gotos are called
our $commands;       # hash of commands to interact user with debugger
# our @stack;          # array of hashes that keeps aliases of DB::'s ours for current frame
                       # This allows us to spy the DB::'s values for a given frame
# our $ddlvl;          # Level of debugger debugging <= @$DB::state
# our $dbg_call;       # keep silent at DB::sub/lsub while do external call from DB::*
# our $inDB;           # Flag which shows we are currently in debugger
# our $inSUB;          # Flag which shows we are currently in debugger
# TODO? does it better to implement TTY object?
our $IN;
our $OUT;
our %options;
our $interaction;    # True if we interact with dbg client
our $variables;      # Hash which defines behaviour for values available through &DB::state
	# There three types of variables:
	# Debugger internal variables -- global values from DB:: package
	# Debugger instance variables -- values which exists in current debugger instance
	# Frame variables -- values for each sub call



# Do DB:: configuration stuff here
# Default debugger behaviour while it is loading
BEGIN {
	$DB::variables =  {()
		,'*'         =>  \&dbg_vrbl
		,single      =>  \&int_vrbl
		,on_frame    =>  \&frm_vrbl
		,file        =>  \&frm_vrbl
		,goto_frames =>  \&frm_vrbl
		,line        =>  \&frm_vrbl
		,package     =>  \&frm_vrbl
		,sub         =>  \&frm_vrbl
		,type        =>  \&frm_vrbl
		,eval        =>  \&frm_vrbl
	};


	$IN                        //= \*STDIN;
	#TODO: cache output until debugger is connected
	$OUT                       //= \*STDOUT;

	#FIX: Where apply 'ddd' from command line?
	DB::new;
	DB::state( single =>  $DB::single );

	$options{ undef }          //=  '';        # Text to print for undefined values

	# $options{ dd }             //=  0;         # controls debugger debugging
	# $options{ ddd }            //=  0;         # print debug info

	$options{ s }              //=  0;         # compile time option
	$options{ w }              //=  0;         # compile time option
	# TODO: camelize options. Q: Why?
	$options{ frames }         //=  -1;        # compile time & runtime option
	$options{ dbg_frames }     //=  0;         # compile time & runtime option

	#options{ save_path } # TODO: save code path for displaying by graphviz
	$DB::postponed{ 'DB::DB' } =  1;

	#NOTE: we should always trace goto frames. Hiding them will prevent
	# us to complete our work - debugging.
	# But we still allow to control this behaviour at compiletime & runtime
	# $options{ trace_goto };    #see DH:import  # compile time & runtime option
	$^P |= 0x80;
}

# TODO: describe qw/ frames dbg_frames trace_load trace_subs
# trace_returns / options


# $options{ NonStop } - if true then 0x20 flag is flushed




# $^P default values
#      ! x
# 0111 0011 1111
# |||| |||| |||^-- Debug subroutine enter/exit.
# |||| |||| ||^--- Line-by-line debugging.
# |||| |||| |^---- Switch off optimizations.
# |||| |||| ^----- Preserve more data for future interactive inspections.
# |||| ||||
# |||| |||^------- Keep info about source lines on which a subroutine is defined.
# |||| ||^-------- Start with single-step on.
# |||| |^--------- Use subroutine address instead of name when reporting.
# |||| ^---------- Report goto &subroutine as well.
# ||||
# |||^------------ Provide informative "file" names for evals based on the place they were compiled.
# ||^------------- Provide informative names to anonymous subroutines based on the place they were compiled.
# |^-------------- Save source code lines into @{"_<$filename"}.
# ^--------------- When saving source, include evals that generate no subroutines.
# < When saving source, include source that did not compile.



# NOTICE: it is better to not use any modules from this one
# because we do not want that they appear to compiler before
# we can track module loading and subs calling process
# Also it is safe that descendant debugger module 'use' us. BUT BE AWARE!!!
# That module should not use any module before this one
# otherwise sub calls and module loading will not be tracked
#
# When we 'use' descendant debugger at the end our module appears last at load chain.
# Also there is a problem how to pass descendant class name to 'use' it.
# Keep this comment for history. Find this commit at 'git blame' to see what was changed
BEGIN {
	if( $options{ w } ) { require 'warnings.pm';  'warnings'->import(); }
	if( $options{ s } ) { require 'strict.pm';    'strict'->import();   }
	if( $options{ d } ) { require 'Data/Dump.pm'; 'Data::Dump'->import( 'pp'); }
	# http://perldoc.perl.org/warnings.html
	# The scope of the strict/warnings pragma is limited to the enclosing block.
	# But this not truth.
	# It is limited to the first enclosing block of the BEGIN block
}


# NOTICE: Because of DB::DB, DB::sub, DB::postpone etc. subs take effect
# as soon as compiled we should &applyOptions at compile time
BEGIN { # Initialization goes here
	# When we 'use Something' from this module the DB::sub is called at compile time
	# If we do not we can still init them when define
	$DB::interaction //=  0;
	# TODO: set $DB::trace at CT

	# Some configuration options may be applied when debugger is loading
	# When debugger is loaded its &import subroutine will be called (see comment there)
	applyOptions();
}



# Hooks to Perl's internals should be first.
# Because debugger or its descendants may call them at compile time
{
	{
		BEGIN{ 'strict'->unimport( 'refs' )   if $options{ s } }

		sub dd {
			eval "use Data::Dump";
			Data::Dump::pp( @_ );
		}



		# Returns TRUE if $filename was compiled/evaled
		# The file is evaled if it looks like (eval 34)
		# But this may be changed by #file:line. See ??? for info
		sub file {
			my $filename =  shift // state( 'file' );

			unless( exists ${ 'main::' }{ "_<$filename" } ) {
				warn "File '$filename' is not compiled yet";

				return;
			}

			return ${ "::_<$filename" };
		}



		# Returns source for $filename
		sub source {
			my $filename =  shift // state( 'file' );

			return   unless file( $filename );

			return \@{ "::_<$filename" };
		}



		# Returns list of compiled files/evaled strings
		# The $filename for evaled strings looks like (eval 34)
		sub sources {
			return grep{ s/^_<// } keys %{ 'main::' }; #/
		}

		sub deparse {
			my( $coderef ) =  shift;
			require B::Deparse;
			return $coderef   unless ref $coderef;
			return B::Deparse->new("-p", "-sC")->coderef2text( $coderef );
		}



		# Returns hashref of traps for $filename keyed by $line
		sub traps {
			#TODO: remove default because current position != view position
			# this makes confusion
			my $filename =  shift // state( 'file' );

			return   unless file( $filename );

			# Keep list of $filenames we perhaps manipulate traps
			$DB::_tfiles->{ $filename } =  1;

			*dbline =  $main::{ "_<$filename" }; #WORKRAOUND RT#119799 (see commit)

			return \%{ "::_<$filename" };
		}



		# Returns TRUE if we can set trap for $file:line
		sub can_break {
			my( $file, $line ) =  @_;

			($file, $line) =  split ':', $file
				unless defined $line;

			return   unless defined( $file =  file( $file ) );

			# TODO: testcase for negative lines
			return ($line<0?-$line-1:$line) <= $#{ "::_<$file" }
				&& ${ "::_<$file" }[ $line ] != 0;

			# http://perldoc.perl.org/perldebguts.html#Debugger-Internals
			# Values in this array are magical in numeric context:
			# they compare equal to zero only if the line is not breakable.
		}
	}



	sub eval_cleanup {
		DB::state( 'inDB', 1 );
		DB::state( 'eval', undef );
	}
	mutate_sub_is_debuggable( \&eval_cleanup, 0 );



	# We put code here to execute it only once
	(my $usercontext =  <<'	CODE') =~ s#^\t\t##gm;
		BEGIN{
			( $^H, ${^WARNING_BITS}, my $hr ) =  @DB::context[1..3];
			%^H =  %$hr   if $hr;
		}
		# $@ is cleared when compiller enters *eval* or *BEGIN* block
		$@ =  $DB::context[4];
	CODE
	# http://perldoc.perl.org/functions/eval.html
	# We may define eval in other package if we want to place eval into other
	# namespace. It will still "doesn't see the usual surrounding lexical scope"
	# because "it is defined in the DB package"
	# sub My::eval {
	sub eval {
		my( $expr ) =  @_;
		# BUG: PadWalker does not show DB::eval's lexicals
		# Q? It is better that PadWalker return undef instead of warn when out of level

		print $DB::OUT "Evaluating '$expr'...\n"   if DB::state( 'ddd' );

		establish_cleanup \&eval_cleanup;
		DB::state( 'eval', 1 );

		my $package =  DB::state( 'package' );
		DB::state( 'inDB', undef );


		# Read BEWARE at DebugHooks.pod about localization of globals
		local $^D;
		local $_ =  $DB::context[5];
		local @_ =  @{ $DB::context[0] };
		eval "$usercontext; package $package;\n#line 1\n$expr";
		#NOTICE: perl implicitly add semicolon at the end of expression
		#HOWTO reproduce. Run command: X::X;1+2
		#
		# print $DB::OUT "Error occur while evaluating: $@"   if $@
		# But if we do this we return wrong value
	}



	# Returns the location where $subname is defined in the form:
	# filename:startline-endline
	sub location {
		my $subname =  shift;

		return   unless $subname;
		return   ">>$subname<<"   if ref $subname; # The subname maybe a coderef

		# The subs from DB::* are not placed here. Why???
		# A? Maybe they are placed after module loaded?
		return $DB::sub{ $subname };
	}



	# Returns list of all defined not ANON subs.
	# We may limit the list by supplying regex
	sub subs {
		return keys %DB::sub   unless @_;

		my $re =  shift;
		return grep { /$re/ } keys %DB::sub;
	}



	# Returns caller frame info with arguments at given level
	# or all call stack with goto frames
	sub frames {
		my $level =  shift;

		if( defined $level ) {
			# https://rt.perl.org/Public/Bug/Display.html?id=126872#txn-1380132
			# Note that we should ignore our frame, so +1
			my @frame =  caller( $level +1 );
			return ( [ @DB::args ], @frame );
		}


		orig_frames()   if $options{ orig_frames };


		# For uninitialized values in frames
		# $wantarray is undefined in void context, for example
		BEGIN{ 'warnings'->unimport( 'uninitialized' )   if $DB::options{ w } }

		my @frames;
		$level =  0;
		local $" =  ' -';

		# The $inDB is an internal variable of DB:: module. If it is true
		# then we know that debugger frames are exists. In other case no sense
		# to check callstask for frames generated by debugger subs
		if( DB::state( 'inDB' ) ) {

			my $found =  0;
			# Skip debugger frames from stacktrace
			while( my @frame =  caller($level++) ) {
				# print "DBGF: @frame[0..3,5]\n"        if $options{ dbg_frames };
				push @frames, [ 'D', [ @DB::args ], @frame]   if $options{ dbg_frames };

				if( $frame[3] eq 'DB::trace_subs' ) {
					$found =  1;
					# my $args =  [ @DB::args ];
					my @gframe =  caller($level);
					if( @gframe  &&  $gframe[ 3 ] eq 'DB::goto' ) {
						# print "DBGF: @gframe[0..3,5]\n"       if $options{ dbg_frames };
						# TODO: implement testcase: 'T' should show args for sub calls
						push @frames, [ 'D', [ @DB::args ], @gframe]   if $options{ dbg_frames };
						$level++;
					}
					else {
						# Because there is no DB::goto frame in stack
						# we are sure that the @DB::goto_frames will not contain
						# goto frames also. But only one initial sub frame
						$level--;
						# use Data::Dump qw/ pp /;
						# print pp \@DB::goto_frames, \@gframe; print "<<<<<<<\n";

						# $frame[3] =  $DB::goto_frames[0][3];
						# push @frames, [ $DB::goto_frames[0][5], $args, @frame ];
					}

					last;
				}

				if( $frame[3] eq 'DB::DB' ) {
					$found =  1;
					last;
				};
			}

			# We can not make $DB::inDB variable private because we use localization
			# In theory someone may change the $DB::inDB from outside
			# Therefore we prevent us from empty results when debugger frames
			# not exist at the stack
			$level =  0   unless $found;
		}

		my $count =  $options{ frames };
		my $ogf =  my $gf =  DB::state( 'goto_frames' );
		while( $count  &&  (my @frame =  caller( $level++ )) ) {
			# The call to DB::trace_subs replaces right sub name of last call
			# We fix that here:
			$frame[3] =  DB::state( 'goto_frames' )->[-1][3]
				if $count == $options{ frames }  && $frame[3] eq 'DB::trace_subs';

			my $args =  [ @DB::args ];
			if( $options{ trace_goto }
				&& $gf->[0][0] eq $frame[0]
				&& $gf->[0][1] eq $frame[1]
				&& $gf->[0][2] == $frame[2]
			) {
				$frame[3] =  $gf->[0][3];
				push @frames, [ $_->[5], $args, @$_[0..3] ]   for @$gf[ reverse 1..$#$gf ];
				$ogf =  $gf;
				$gf  =  $gf->[0][4];
			}

			push @frames, [ $ogf->[0][5], $args, @frame ];
		} continue {
			$count--;
		}


		return @frames;
	}



	# TODO: implement $DB::options{ trace_internals }
	sub mcall {
		my $method  =  shift;
		my $context =  DB::state( 'instance' );

		print "mcall ${context}->$method\n"
			if DB::state( 'ddd' );

		my $sub =  $context->can( $method );
		scall( $sub, $context, @_ );
	}



	sub scall {
		my $sub =  sub_name( $_[0] ) || $_[0];
		my $ddd =  DB::state( 'ddd' );
		my( $from, $f, $l );
		if( $ddd ) {
			my $lvl =  0;
			if( (caller 1)[3] eq 'DB::mcall' ) {
				$lvl++;
			}

			{ local $" =  ', '; $sub .=  "( @_[ 1..$#_ ] )"; }

			($f, $l) =  (caller $lvl)[1,2];
			$f =~ s".*?([^/]+)$"$1";
			$from =  (caller $lvl+1)[3];

			print $DB::OUT ">> scall from $from($f:$l) --> $sub\n";
		}

		# die "You can make debugger call only from debugger"
		# 	unless DB::state( 'inDB' );


		# FIX: http://perldoc.perl.org/perldebguts.html#Debugger-Internals
		# (This doesn't happen if the subroutine -was compiled in the DB package.)
		# ...was called and compiled in the DB package

		# Any subroutine call invoke DB::sub again
		# The right way is to turn off 'Debug subroutine enter/exit'
		# local $^P =  $^P & ~1;      # But this works at compile time only.
		# So prevent infinite DB::sub reentrance manually. One way to compete this:
		# my $stub = sub { &$DB::sub };
		# local *DB::sub =  *DB::sub; *DB::sub =  $stub;
		# Another: the { inDB } flag

		#IT: Call other debugger commands from current command
		my $old_cmd =  DB::state( 'cmd' );

		# Manual localization
		my $scall_cleanup =  sub {
			print_state "Debugger command DONE: $sub  "   if $ddd;

			# NOTICE: Because  we are in debugger here we should setup { inDB }
			# flag but we are leaving debugger and interesting at user's context

			DB::state( 'cmd', $old_cmd ); DB::state( 'single', 0, 1 )   if $old_cmd;
			# $DB::single =  DB::state( 'single' );
			DB::state( 'single', DB::state( 'single' ) ) unless $old_cmd;

			my $dd;
			DB::DESTROY   if ($dd =  DB::state( 'dd' ))  &&  $sub =~ /$dd/;

			# Enable debugging after current command is finished
			if( my $debug =  DB::state( 'debug' ) ) {
				DB::state( 'debug', undef );
				my( $verbose, $sub ) =  $debug =~ /^(\d+)?(?:@(.*))?$/;
				# Set or flush debug flags depending on user's input
				DB::state( 'ddd', $verbose // undef );
				DB::state( 'dd',  $sub     // undef );
			}


			print $DB::OUT "<< scall back $from($f:$l) <-- $sub\n"   if $ddd;
		};
		mutate_sub_is_debuggable( $scall_cleanup, 0 );
		establish_cleanup $scall_cleanup;

		# TODO: testcase 'a 3 DB::state( dd => 1 )'


		# Create new debugger's state instance
		my $dd;
		if( ($dd =  DB::state( 'dd' ))  &&  $sub =~ /$dd/ ) {
			# NOTICE: We should not set debugger states directly when create
			# new state instance. We will not see changes at debug output
			# So we use &DB::state after instance initialization
			DB::new();
			DB::state( 'single', 1 );
			DB::state( 'inDB', undef );
			$^D |=  1<<30;
		}
		else {
			DB::state( 'single', 0, 1 ); # Prevent debugging for next call # THIS CONTROLS NESTING
			DB::state( 'cmd', 1 );
		}

		print $DB::OUT "Call debugger command: $sub\n"   if $ddd;
		return shift->( @_[ 1..$#_ ] );

		# my $method =  shift;
		# my $context =  shift;
		# &{ "$context::$method" }( @_ );
	}



	sub save_context {
		@DB::context =  ( \@_, (caller 2)[8..10], $@, $_ );
		print_state "\nTRAPPED IN  ", "\n\n"   if _ddd;
		DB::state( 'inDB', 1 );
	}



	# WORKAROUND: &restore_context is called outside of DB::DB, so we should stop debugging it
	# to prevent $file:$line updated in unexpected way
	mutate_sub_is_debuggable( \&restore_context, 0 );
	sub restore_context {
		DB::state( 'inDB', undef );
		print_state "\nTRAPPED OUT  ", "\n\n"   if _ddd;
		$@ =  $DB::context[ 4 ];
		# WARNING: Do not keep any references to user's data, in other case we postpone
		# object desctruction process.
		@DB::context =  (); # TODO: IT
	}
} # end of provided DB::API





sub import { # NOTE: The import is called at CT yet
	# CT of callers module. For this one it is RT
	my $class =  shift;


	# There are two states: debugger is loaded or not (still loading)
	# One options define debugger behaviour while it is loading
	# Others define debugger behaviour while main program is running

	# NOTICE: it is useless to set breakpoints for not compiled files
	# TODO: spy module loading and set breakpoints
	#TODO: Config priority: conf, ENV, cmd_line


	# Parse cmd_line options:
	if( $_[0]  and  $_[0] eq 'options' ) {
		my %params =  @_; # FIX? the $_[1] should be HASHREF; $options = @_[1]
		@DB::options{ keys %{ $params{ options } } } =  values %{ $params{ options } };
	}
	else {
		for( @_ ) {
			if( /^(\w+)=([\w\d]+)/ ) {
				$DB::options{ $1 } =  $2;
			}
			else {
				$DB::options{ $_ } =  1;
			}
		}
	}


	# Default debugger behaviour for main script
	$DB::options{ trace_goto } //=  1;


	# Now debugger and all required modules are loaded. We should set
	# corresponding perl debugger *internal* values based on given %DB::options
	applyOptions();
	DB::state( 'inDB', undef );
}



# use Sub::Identify qw/ sub_name /;
use B qw(svref_2object);
sub sub_name {
    return unless ref( my $r = shift );
    return unless my $cv = svref_2object( $r );
    return unless $cv->isa( 'B::CV' )
              and my $gv = $cv->GV
              ;
    my $name = '';
    if ( my $st = $gv->STASH ) {
        $name = $st->NAME . '::';
    }
    my $n = $gv->NAME;
    if ( $n ) {
        $name .= $n;
        if ( $n eq '__ANON__' ) {
            $name .= ' defined at ' . $gv->FILE . ':' . $gv->LINE;
        }
    }
    return $name;
}



# We define posponed/sub as soon as possible to be able watch whole process
# NOTICE: At this sub we reenter debugger
sub postponed {
	#TODO: implement local_state to localize debugger state values
	my $old_inDB =  DB::state( 'inDB' );
	DB::state( 'inDB', 1 );
	#FIX: process exceptions
	emit( 'trace_load', @_ );

	# When we are in debugger and we require module the execution will be
	# interrupted and we REENTER debugger
	# TODO: study this case and IT:
	# T: We are { dd } and run command that 'require'
	DB::state( 'inDB', $old_inDB );
}



our %sig =  (()
	,trap    =>  \&trap
	,untrap  =>  \&untrap
);


mutate_sub_is_debuggable( \&reg, 0 );
sub reg {
	my( $sig, $name, @extra ) =  @_;

	if( exists $DB::sig{ $sig } ) {
		return $DB::sig{ $sig }->( $name, @extra );
	}
	else {
		return default_handler( $sig, $name, @extra );
	}
}



sub unreg {
	my( $sig, $name, @extra ) =  @_;

	if( exists $DB::sig{ $sig } ) {
		return $DB::sig{ "un$sig" }->( $name, @extra );
	}
	else {
		return default_unhandler( $sig, $name, @extra );
	}
}



sub emit {
	my( $name ) =  ( shift );

	print $DB::OUT "Emit event '$name' from ", (caller)[1,2], "\n"   if DB::state( 'ddd' );

	# Get subscribers for the event
	my $ev; {
		no strict 'refs';
		$ev =  defined &{ "${name}_info" }
			? &{ "${name}_info" }( @_ )
			: default_handler_info( $name )
		;
	}

	my $res =  [];
	# Events are emitted in context of handler. Event handler should be at least
	# HASHREF with key 'code' having CODEREF to sub which will process event
	push @$res, process( $ev->{ $_ }, @_ )   for keys %$ev;

	print $DB::OUT "Event '$name' DONE\n"   if DB::state( 'ddd' );

	return $res;
}



sub default_handler_info {
	return DB::state( "on_$_[0]" ) // {};
}



sub default_handler {
	my( $sig, $name ) =  @_;
	my $subscribers =  DB::state( "on_$sig" );
	$subscribers =  DB::state( "on_$sig", {} )   unless $subscribers;

	# HACK: Autovivify subscriber if it does not exists yet
	# Glory Perl. I love it!
	return \$subscribers->{ $name };
}



sub default_unhandler {
	my( $sig, $name ) =  @_;
	my $subscribers =  DB::state( "on_$sig" );

	delete $subscribers->{ $name };
	DB::state( "on_$sig", undef )   unless keys %$subscribers;
}



sub trap_info {
	my( $file, $line ) =  @_;

	return DB::traps( $file )->{ $line };
}



sub trap {
	my( $name, $file, $line ) =  @_;
	my $traps =  DB::traps( $file );

	# HACK: Autovivify subscriber if it does not exists yet
	# Glory Perl. I love it!
	return \$traps->{ $line }{ $name };
}



sub untrap {
	my( $name, $file, $line ) =  @_;
	my $traps =  DB::traps( $file );

	#TODO: clear all traps in all files
	#TODO: clear all specific traps, maybe in all files
	delete $traps->{ $line }{ $name };

	# Remove info about trap from perl internals if no common traps left
	# After this &DB::DB will not be called for this line
	unless( keys %{ $traps->{ $line } } ) {
		# NOTICE: Deleting a key does not remove a breakpoint for that line
		# Because key deleting from common hash does not update internal info
		# TODO: bug report
		# WORKAROUND: we should explicitly set value to 0 to signal perl
		# internals there is no trap anymore then delete the key
		$traps->{ $line } =  0;
		delete $traps->{ $line };
	}
	#IT: Deleting one subscriber should keep others

	return;
}



# TODO: implement: on_enter, on_leave, on_compile
sub DB_my {
	&save_context;
	establish_cleanup \&restore_context;

	my( $p, $f, $l ) =  init();
	print_state( "DB::DB  ", sprintf "\n    cursor(DB) => %s, %s, %s\n" ,$p ,$f, $l )   if DB::state( 'ddd' );

	emit( 'trace_line' )   if $DB::trace;
	#TODO: $DB::signal $DB::trace


	my $stop    =  List::Util::any { $_ } @{ emit( 'trap', $f, $l )     };
	my $confirm =  List::Util::all { $_ } @{ emit( 'stop', $p, $f, $l ) };

	#IT: stop on breakpoint while stepping
	return   unless $stop  ||  $DB::single && $confirm  ||  $DB::signal;
	# Stop if required or we are in step-by-step mode


	print_state "\n\nStart to interact with user\n", "\n\n"   if DB::state( 'ddd' );

	emit( 'bbreak'   );
	emit( 'interact' );
	emit( 'abreak'   );
}



sub DB {
	# WORKAROUND: Thanks for mst
	# the 'sub DB' pad stack isn't getting pushed to allocate a new pad if
	# you set '$^D|=(1<<30) and reenter DB::DB
	# So I call general sub. '&' used to leave @_ intact
	&DB_my;
}



sub init {
	# For each step at client's script we should update current position
	# Also we should do same thing at &DB::sub
	my( $p, $f, $l ) = caller(2);
	state( 'package', $p );
	state( 'file',    $f );
	state( 'line',    $l );

	# Someone may stop client's code running through perl debugger interface
	# For example until the first line of client's code the $DB::single == 0
	# When ($^P & 0x20) perl set $DB::single = 1 before execution of first line
	# So we should update our state
	DB::state( 'single', $DB::single );


	# Commented out because of:
	# https://rt.perl.org/Ticket/Display.html?id=127249
	# die ">$DB::file< ne >" .file( $DB::file ) ."<"
	# 	if $DB::file ne file( $DB::file );

	return( $p, $f, $l );
}



# When handler returns itself (HASHREF) as result it will keep processing (like 'redo'):
# specified handler at 'code' key will be reinvoked
# When handler returns ARRAYREF specified handler also will be reinvoked with
# evaluated results for each returned item in that array
sub process {
	my( $handler ) =  @_;
	my $htype      =  ref $handler;

	my( $code, @args );
	do {
		if( $htype eq 'ARRAY' ) {
			print $DB::OUT "Got list of expressions to evaluate in usercontext\n"
				if DB::state( 'ddd' );
			$code =  shift @$handler;
			@args =  ();
			for my $expr ( @$handler ) {
				# $expr should be simple string. If it is not it is special
				push @args, ref $expr ? process( $expr ) : [ DB::eval( $expr ) ];
				if( $@ ) {
					# Pass reference to copy of error message. Value of error
					# message (global variable) may be changed by anyone
					$args[-1] =  bless { error => $@ }, 'DB::Error';
				}
			}
		}
		elsif( $htype eq 'HASH' ) {
			$code =  $handler->{ code };
			@args =  @_;
		}
		else {
			die "Handler type should be ARRAY or HASH";
		}

		die "Handler is not defined"   unless $code;

		if( DB::state( 'ddd' ) ) {
			my $sub =  sub_name( $code ) || $code;
			my @first =  ref $args[0] eq 'ARRAY' ? @{ $args[0] } : $args[0] // '';
			print $DB::OUT "Run callback: $sub @first ( @args )\n"
		}
	} while(
		defined( $handler =  scall( $code, @args ) )
		&&     ( $htype   =  ref $handler          )
	);

	return $handler;
}



# TODO: Before run the programm we could deparse sources and insert some code
# in the place of 'goto'. This code may save __FILE__:__LINE__ into DB::
sub goto {
	#FIX: IT: when trace_goto disabled we can not step over goto
	return   unless $options{ trace_goto };
	return   if DB::state( 'inDB' );

	my $old_inDB =  DB::state( 'inDB' );
	DB::state( 'inDB', 1 );

	DB::state( 'single', 0 )   if DB::state( 'single' ) & 2;
	push_frame( my $tmp =  $DB::sub, 'G' );
	DB::state( 'inDB', $old_inDB )
};



{
#package DB::Tools;
# my $x = 0;
# use Data::Dump qw/ pp /;
#Q: Why &DB::sub is called for &pop_frame despite on it is compiled at DB:: package
# when Scope::Cleanup?
mutate_sub_is_debuggable( \&pop_frame, 0 );
sub pop_frame {
	#NOTICE: We will fall into infinite loop if something dies inside this sub
	#because this sub is called when flow run out of scope.
	#TODO: Put this code into eval block

	my $old_inDB =  DB::state( 'inDB' );
	DB::state( 'inDB', 1 );
	emit( 'pop_frame' );
	DB::state( 'inDB', $old_inDB );
}

}



sub trace_returns {
	DB::state( 'inDB', 1 );
	#FIX: process exceptions
	emit( 'trace_returns', @_ );
	DB::state( 'inDB', undef );
}



sub push_frame {

	print_state "BEFORE CALL: $_[0]  "   if _ddd;
	my $old_inDB =  DB::state( 'inDB' );
	DB::state( 'inDB', 1 );

	emit( 'push_frame', @_ );

	if( DB::state( 'ddd' ) ) {
		print $DB::OUT "STACK:\n";
		DB::state( 'stack' );
	}

	DB::state( 'inDB', $old_inDB );
	print_state "BEFORE CALL DONE: $_[0]  "   if _ddd;
}



# The sub is installed at compile time as soon as the body has been parsed
sub sub {
	#FIX: where to setup 'inDB' state?
	print_state "DB::sub  ", "  -->  " .(sub_name( $DB::sub ) // $DB::sub) ."\n"
		if sub{ DB::state( 'ddd' ) }->() && $DB::sub ne 'DB::can_break';
		#TODO: We could use { trace_internals } flag to see debugger calls

	if( sub{ DB::state( 'inDB' ) }->()
	) {
		BEGIN{ 'strict'->unimport( 'refs' )   if $options{ s } }
		# TODO: Here we may log internall subs call chain

		# sub{ DB::state( 'inDB', undef ) }->();
		#TODO: Do not create extra frames. Speed optimization?
		# replace return -> goto
		return &$DB::sub
	}

	# manual localization
	establish_cleanup \&DB::pop_frame; # This should be first because we should
	# start to guard frame before any external call

	#FIX: do not call &pop_frame when &push_frame FAILED
	sub{ push_frame( my $tmp =  $DB::sub, 'C' ) }->();


	{
		BEGIN{ 'strict'->unimport( 'refs' )   if $options{ s } }


		if( wantarray ) {                             # list context
			my @ret =  &$DB::sub;
			trace_returns( @ret );
			return @ret;
		}
		elsif( defined wantarray ) {                  # scalar context
			my $ret =  &$DB::sub;
			trace_returns( $ret );
			return $ret;
		}
		else {                                        # void context
			&$DB::sub;
			trace_returns;
			return;
		}
	}


	die "This should be reached never";
	#NOTICE: This reached when someone leaves sub by calling 'next/last' outside of LOOP block
	#Then 'return' is not called at all???
};



# FIX: debugger dies when lsub is not defined but the call is to an lvalue subroutine
# The perl may not "...fall back to &DB::sub (args)."
# http://perldoc.perl.org/perldebguts.html#Debugger-Internals
sub lsub : lvalue {
	my $x;
	if( DB::state( 'inDB' ) ) {
		BEGIN{ 'strict'->unimport( 'refs' )   if $options{ s } };
		$x =  &$DB::sub
	}
	else {
		# manual localization
		establish_cleanup \&sub_returns;
		push @{ DB::state( 'stack' ) }, {
			single      =>  DB::state( 'single' ),
			sub         =>  $DB::sub,
			goto_frames =>  DB::state( 'goto_frames' ),
		};

		DB::state( 'goto_frames', [] );


		# HERE TOO client's code 'caller' return wrong info
		trace_subs( 'L' );

		DB::state( 'single', 0 )   if DB::state( 'single' ) & 2;
		{
			BEGIN{ 'strict'->unimport( 'refs' )   if $options{ s } }
			$x =  &$DB::sub;
		}
	}

	$x;
};



# It is better to load modules at the end of DB::
# because of they will be visible to 'trace_load'
use Devel::DebugHooks::Commands;


# DB::state( 'inDB', undef );
# TODO: After this module is loaded the &import is called
# Enable debugging for importing process of DB:: modules
# If you flush { inDB } we will trace sub calls while loading those modules



1;

__END__

=head1 SUPPORT

Bugs may be reported via RT at

 https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-DebugHooks

Support by IRC may also be found on F<irc.perl.org> in the F<#debughooks>
channel.

=head1 AUTHOR

Eugen Konkov <kes-kes@yandex.ru>

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2016 Eugen Konkov

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

Describe what is used by perl internals from DB:: at compile time
${ "::_<$filename" } - $filename
@{ "::_<$filename" } - source lines. Line in compare to 0 shows trapnessability
%{ "::_<$filename" } - traps keyed by line number ***
$DB::sub - the current sub
%DB::sub - the location of sub definition
@DB::args - ref to the @_ at the given level at caller(N)
if the sub returns the @DB::args becomes dirty and we can not access its values
&DB::goto, &DB::sub, &DB::lsub, &DB::postponed - called at appropriate events
$^P - flags to control behaviour
$DB::postponed{subname} - trace sub loads        ***
$DB::trace, $DB::single, $DB::signal - controls if the program should break

initialization steps: rc -> env


goto implicitly changes the value of $DB::sub

At compile time $DB::single is 0

Which data is preserved by forth bit of $^P?

How to debug lvalue subs?

The DOC must describe that DB::sub should have :lvalue attribute
if DB::lsub is not defined. Whithout that the:
'falling back to &DB::sub (args).' is not possible



Can not control what value is assigned to lvalue sub


+
if sub does not exists lsub is not called at all

+
The caller behaves differently in lsub in compare to sub
http://paste.scsys.co.uk/502493
http://paste.scsys.co.uk/502494

no description/link for the $DEBUGGING variable in perlvar
>>perl -Dxxx command described in perlrun

Why the 'DB::' namespace is exluded from loading subs process?
whereas 'DB::postpone' is works fine for whole module
BEGIN {
	$DB::postponed{ 'DB::DB' } =  1;
} # The DB::postpone( 'DB::DB' ) is not called



+
Why the DB::DB is called twice for:
print "@{[ (caller(0))[0..2] ]}\n";
but only one for this:
print sb();
A: It is called once for caller(0) and second for whole line.
It is called once for each statement at line, maybe.


+
use should have args. and the caller called from DB:: namespace should set @DB::args
at compile time 'caller' also does not fill @DB::args
BEGIN {
	print caller, @DB::args
}
A: Try, to ensure the DB::args used after the call ot caller
BEGIN {
	@caller =  caller
	print @caller, @DB::args
}



How 'the first non-DB piece of code' is calculated for the 'eval'?



#BUG? I can ${ '!@#$' } =  3, but can not my ${ '!@#$' }


BUG?
The localization of $DB::single works fine, but the reference to it does not work:
	{
		$DB::single =  7; my $x =  \$DB::single;
		print "Before: ". \$DB::single ." <<$x $$x\n";
		local $DB::single =  0;
		print "After: ". \$DB::single ." <<$x $$x\n";
	}

The output:
Before: SCALAR(0x10f8310) <<SCALAR(0x10f8310) 7
After: SCALAR(0x110cbc8) <<SCALAR(0x10f8310) 0

Where as works fine:
	{
		$DB::z =  7; my $x =  \$DB::z;
		print "Before: ". \$DB::z ." <<$x $$x\n";
		local $DB::z =  0;
		print "After: ". \$DB::z ." <<$x $$x\n";
	}
The output:
Before: SCALAR(0x134d398) <<SCALAR(0x134d398) 7
After: SCALAR(0x1239bc8) <<SCALAR(0x134d398) 7

We see that in *first* example the new variable is created: The new address of $DB::single is SCALAR(0x110cbc8)
but when assigning to $DB::single the value by old reference (SCALAR(0x10f8310) changed too.
In *second* example we see that addressing works in same manner, but value 7 is preserved as expected.

Why the value of $DB::single is not preserved?

	# my $y =  \$DB::single;
	# # Can not use weaken. See error at 'reports/readline' file
	# use Scalar::Util 'weaken';
	# weaken $y;
	# Because of $DB::single magic we can not access to old value by reference
	# The localization is broken if we save a reference to $DB::single
	# {
	# 	my $x =  $DB::single;
	# 	print "Before: ". \$DB::single ." <<$DB::single $x >$y $$y\n"; # $$x == 0
	# 	local $DB::single =  $DB::single +1;
	# 	print "After: ". \$DB::single ." <<$DB::single $x >$y $$y\n";  # $$x == 1, not 0
	# }
	# print "OUT: ". \$DB::single ." <<$DB::single - $x - $$x >$y\n";

	# {
	# 	print "BEFORE: $DB::single\n";
	# 	local $DB::single =  7;
	# 	print "AFTER $DB::single\n";
	# }
	# print "OUT $DB::single\n";

	# BUG: The perl goes tracing if you uncomment this
	# { local $DB::trace =  1; }
	# # But it shows us the value 0 but internally it is 1
	# die $DB::trace   if $DB::trace != 0;



sub sub {
	...
	# BUG: without +0 the localized value is broken
	local $DB::single =  ($DB::single & 2) ? 0 : $DB::single+0;


Breakpoint does not work for this when hash key is initialized
  b  x64:   my $hash = $c->stash->{'mojo.content'} ||= {};

#TODO: $X=(condition)

The debugger do not single step into sub called from string



Notice strange file:line
POP  FRAME <<<< l:0 b:0:0 e:1 s:1 t:1  --  Apache::DB::handler@1
    /home/kes/perl_lib/lib/perl5/x86_64-linux-gnu-thread-multi/Apache/DB.pm:77 }

	else {
		if (ref $r) {
		$SIG{INT} = \&DB::catch;
		$r->register_cleanup(sub {
			$SIG{INT} = \&DB::ApacheSIGINT();
		});
		}
	}

    print "HERE: " .$DB::single; #line 77
    DB::state( 'trace', 1 );
    $DB::single = 1;
    print "HERE: A" .$DB::single;


  print "DONE\n";

  print "DONE\n";
    return 0;

}

Maybe because DESTROY is called at first OP after closing block

TODO: Allow to eval: 'shift @_' in debugger
