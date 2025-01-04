###
###  Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.
###
###  Signal processinng enhancememnt to the Fred Fish Dbug module.
###
###  Module: Fred::Fish::DBUG::Signal
###
###  Note: All methods starting with 'on_' are calls to stubs that call
###        unexported functions defined in Fred::Fish::DBUG::ON ...
###
###  Note: All methods starting with '_' are unexported local functions.

=head1 NAME

Fred::Fish::DBUG::Signal - Fred Fish library extension to trap Signals.

=head1 SYNOPSIS

  use Fred::Fish::DBUG::Signal;
    or
  require Fred::Fish::DBUG::Signal;

=head1 DESCRIPTION

F<Fred::Fish::DBUG::Signal> is a pure Perl extension to the F<Fred::Fish::DBUG>
module.  Using this module allows you to trap the requested signal and write
the event to your fish logs.  Kept separate since not all OS support Signal
handling.  Also the list of Signals supported varry by OS.

You are not required to use this module when trapping signals, but it's useful
for logging in B<fish> that a signal was trapped and where in the code the
signal was trigereed when seeing how a caught signal affects your code.

=head1 FUNCTIONS

=over 4

=cut 

package Fred::Fish::DBUG::Signal;


use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Fred::Fish::DBUG::ON 2.10;

use Perl::AtEndOfScope;
use Config qw( %Config );

use Perl::OSType ':all';
use FileHandle;
use File::Basename;
use Cwd 'abs_path';
use Sub::Identify 'sub_fullname';

$VERSION = "2.10";
@ISA = qw( Exporter );

@EXPORT = qw( DBUG_TRAP_SIGNAL  DBUG_FIND_CURRENT_TRAPS  DBUG_DIE_CONTEXT

              DBUG_SIG_ACTION_EXIT13     DBUG_SIG_ACTION_EXIT_SIGNUM
              DBUG_SIG_ACTION_LOG        DBUG_SIG_ACTION_DIE
              DBUG_SIG_ACTION_REMOVE
            );

@EXPORT_OK = qw( );

# Constants to use to tell what to do with the trapped signals ... (never use 0)
use constant DBUG_SIG_ACTION_EXIT13      => 1;
use constant DBUG_SIG_ACTION_EXIT_SIGNUM => 2;
use constant DBUG_SIG_ACTION_LOG         => 3;
use constant DBUG_SIG_ACTION_DIE         => 4;
use constant DBUG_SIG_ACTION_REMOVE      => 55;
use constant DBUG_SIG_ACTION_UNKNOWN     => 99;   # Not exposed!


# These hash variables holds all the global variables used by this module.
my %dbug_signal_vars;     # The signal vars can cross fish frames.

# --------------------------------
# This BEGIN block handles the initialization of the signal trapping logic!
# --------------------------------
BEGIN
{
   # All fish frames will share the same signal info.
   my (%details, %defaults);
   $dbug_signal_vars{recursion} = 0;
   $dbug_signal_vars{forward_signals} = \%details;
   $dbug_signal_vars{original_signal_action} = \%defaults;
   return;
}

# --------------------------------
# END is automatically called when this module goes out of scope!
# --------------------------------
END
{
   DBUG_ENTER_FUNC (@_);

   # Clear any signals trapped by this module ...
   my $pkg = __PACKAGE__ . "::";
   my $clr_sig_flg = 0;
   foreach ( sort keys %SIG ) {
      if ( defined $SIG{$_} && $SIG{$_} =~ m/^${pkg}/ ) {
         on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_INFO,
                                 "Clearing Signal (%s) [%s]", $_, $SIG{$_} );

         # Reset to what the signal was originally ....
         $SIG{$_} = $dbug_signal_vars{original_signal_action}->{$_};
         $clr_sig_flg = 1;
      }
   }

   on_printing ("\n")  if ( $clr_sig_flg );

   DBUG_VOID_RETURN ();
}


# ------------------------------------------------------------------------------
# Set up to call non-exposed methods in Fred::Fish::DBUG:ON.
# ------------------------------------------------------------------------------
sub on_printing           { return ( Fred::Fish::DBUG::ON::_printing (@_) ); }
sub on_indent             { return ( Fred::Fish::DBUG::ON::_indent (@_) ); }
sub on_get_func_info      { return ( Fred::Fish::DBUG::ON::_get_func_info (@_) ); }
sub on_eval_depth         { return ( Fred::Fish::DBUG::ON::_eval_depth (@_) ); }
sub on_dbug_called_by     { return ( Fred::Fish::DBUG::ON::_dbug_called_by (@_) ); }
sub on_dbug_hack          { return ( Fred::Fish::DBUG::ON::_dbug_hack (@_) ); }
sub on_get_global_var     { return ( Fred::Fish::DBUG::ON::_get_global_var (@_) ); }
sub on_set_global_var     { return ( Fred::Fish::DBUG::ON::_set_global_var (@_) ); }
sub on_dbug_print_pkg_tag { return ( Fred::Fish::DBUG::ON::_dbug_print_pkg_tag (@_) ); }
sub on_get_filter_color   { return ( Fred::Fish::DBUG::ON::_get_filter_color (@_) ); }
sub on_filter_on          { return ( Fred::Fish::DBUG::ON::_filter_on (@_) ); }
sub on_dbug_level         { return ( Fred::Fish::DBUG::ON::dbug_level (@_) ); }

# ==============================================================================
# Start of Signal Handling Extenstion to this module ...
# ==============================================================================

# Only for use by Fred::Fish::DBUG::SignalKiller to flag that we've replaced
# Perl's core 'die' with a custom version.
# Must be called from Fred::Fish::DBUG::SignalKiller::_custom_fish_die(),
# not from it's BEGIN block so can detect if you overrode the override!
sub _dbug_enable_signal_suicide
{
   $dbug_signal_vars{LOG_NOW_WORKS_IN_DIE} = 1;
   return;
}


# ==================================================================
# Do we need to disable fish tracing in the END blocks?
# When calling an untrapped die, we won't be calling DBUG_LEAVE to
# handle this for us!
# Triggered by action:  DBUG_SIG_ACTION_DIE
# ------------------------------------------------------------------
sub _dbug_turn_off_end_while_dying
{
   my $special_flag = shift;     # Called by a trapped die(2)/warn(1) signal?
                                 # 0 - for all other signals.

   # It's a no-op unless fish is on & we requested suppressing fish in END.
   return  unless ( on_get_global_var('on') && on_get_global_var('no_end') );

   # Don't disable fish if we're just going to call DBUG's custom die next ...
   if ( $dbug_signal_vars{die_trapped} && $special_flag != 2 ) {
      my $s = $SIG{__DIE__} || "";
      my $ref = $dbug_signal_vars{forward_signals}->{__DIE__};
      return  if ( $s eq $ref->{SAVE_SIG} );
   }

   # --- Now lets disable fish in the END blocks ...

   # There is always at least one "eval" around most called signals ...
   my $eval_cnt = on_eval_depth ();

   # DBUG_PRINT ("TURN END OFF", "Count: %d (%d) [Flag: %d]", $eval_cnt, $^S, $special_flag);

   # Should we shut fish down immediately?
   # Checking if we are processing an untrapped die request!
   if ( $special_flag ) {
      on_set_global_var('on', 0)       if ( $eval_cnt <= 0 );   # Die/Warn ...
   } else {
      on_set_global_var('on', 0)       if ( $eval_cnt <= 1 );   # Other ...
   }

   return;
}


# --------------------------------
# See DBUG_TRAP_SIGNAL() for more info on what the args mean ...
# Returns:
#  -2 : No such context. Request ignored.
#  -1 : No such action.  Request ignored.
#   0 : No such signal.  Request ignored.
#   1 : Signal is now trapped!  Forwarding info in %dbug_signal_vars.
# --------------------------------
# %action_to_take hash has 5 keys:
#   1) ACTION  - The type of action to take.
#   2) EXIT    - The exit status for the program to use.
#   3) FUNC    - undef or an array of funcs to call as code ref.
#   4) NAME    - undef or an array of fully qualified string of func names.
#   5) CONTEXT - Will be 0 unless the FUNC array contain 1 or more entries.
#                Then it tells what to do if these FUNCs call die! (1 or 2)
#   The REMOVE action is handled elsewhere!
# --------------------------------
sub _dbug_log_signal
{
   my $sig     = shift;   # The signal to trap ...
   my $action  = shift || DBUG_SIG_ACTION_UNKNOWN;
   my $context = shift;   # 1 or 2 ... what to do if die is called via @flst!
   my @flst    = @_;      # The list of funcs to forward to.

   return (0)   unless ( $sig );

   $sig = uc ($sig);

   # These signals are special cases not in %SIG by default!
   # They are also not in $Config{sig_name} or $Config{sig_num} arrays!
   my $special_signals = ( $sig eq "__DIE__" || $sig eq "__WARN__" );

   # Disallow signals not in %SIG! (or one of the special cases)
   return (0)  unless ( $special_signals || exists $SIG{$sig} );

   # Save whatever action the signal currently does.
   my $saved_signal = $SIG{$sig};

   # ----------------------------------------------------------
   # Calculate the signal number to use as the exit status ...
   # ----------------------------------------------------------
   my $exit_sts = 13;
   if ( $special_signals && $action == DBUG_SIG_ACTION_EXIT_SIGNUM ) {
      # It's not in $Config{sig_name} or $Config{sig_num} arrays!
      # So use some really big numbers for the exit status!
      # So the numbers are unique for all OS.  (255 is biggest allowed.)
      $exit_sts = ($sig eq "__DIE__") ? 240 : 241;

   } elsif ( $action == DBUG_SIG_ACTION_EXIT_SIGNUM ) {
      $exit_sts = -1;
      my @numbers = split (" ", $Config{sig_num});
      my @names   = split (" ", $Config{sig_name});
      foreach (0..$#names) {
         if ( $names[$_] eq $sig ) {
            $exit_sts = $numbers[$_];
            last;
         }
      }

      return (0)  if ( $exit_sts == -1 );    # No such signal, shouldn't happen.

   } elsif ( $action == DBUG_SIG_ACTION_EXIT13 ||
             $action == DBUG_SIG_ACTION_LOG ||
             $action == DBUG_SIG_ACTION_DIE ) {
      ;

   } else {
      return (-1);   # Unknown action ... Trap request ignored!
   }

   # ----------------------------------------------------------
   # Now set up the requested action to take ...
   # ----------------------------------------------------------
   my %action_to_take;
   $action_to_take{ACTION} = $action;
   $action_to_take{CONTEXT} = 0;   # Assume no funcs to forward to ...

   if ( $action == DBUG_SIG_ACTION_EXIT13 ||
        $action == DBUG_SIG_ACTION_EXIT_SIGNUM ) {
      $action_to_take{EXIT} = $exit_sts;       # Abort program with this status.
   } else {
      $action_to_take{EXIT} = 0;
   }

   my (@codes, @names);
   my $drop = 0;

   # ---------------------------------------------------------------------------
   # Will we be forwarding any trapped signal(s) ???
   # All strings are converted to code references for reliable execution logic.
   # Anything that can't be converted to a code reference will be tossed!
   # ---------------------------------------------------------------------------
   foreach my $func ( @flst ) {
      my ( $code, $name );

      unless ( $func ) {
         next;   # It's a no-op ...

      } elsif ( $func eq "IGNORE" || $func eq "DEFAULT" ) {
         next;   # It's another no-op ...

      } else {
         ( $code, $name ) = on_get_func_info ( $func, "forward ${sig} to" );
      }

      # We found the code reference to use ...
      if ( $code && $name ) {
         push (@codes, $code);
         push (@names, $name);

      } else {
         # warn ("Unknown function [$func].  Tossing it as a custom forwarding function!\n");
         ++$drop;
      }
   }   # end foreach $func loop ...

   # Save the forwarding information ...
   if ( $#codes != -1 ) {
      $action_to_take{FUNC} = \@codes;
      $action_to_take{NAME} = \@names;
      $action_to_take{CONTEXT} = $context;
      return (-2)  unless ( 1 <= $context && $context <= 3 );
   } elsif ( $drop == 1 ) {
      warn ( "The passed function name was not defined properly.\n",
             "So nothing will be forwarded.\n" );
   } elsif ( $drop > 1 ) {
      warn ( "None of the passed function names were defined properly.\n",
             "So nothing will be forwarded.\n" );
   }

   # -----------------------------------------------------------
   # Save the signal results ... No errors allowed after this!
   # -----------------------------------------------------------
   $dbug_signal_vars{forward_signals}->{$sig} = \%action_to_take;
   unless ( exists $dbug_signal_vars{original_signal_action}->{$sig} ) {
      $dbug_signal_vars{original_signal_action}->{$sig} = $saved_signal;
   }

   # -----------------------------------------------------------
   # Now update the signal hash itself ... We're ready to go!
   # -----------------------------------------------------------
   unless ( $special_signals ) {
      $SIG{$sig} = __PACKAGE__ . "::_dbug_normal_signals";

   } elsif ( $sig eq "__DIE__" ) {
      # return (-1) if ( $action == DBUG_SIG_ACTION_LOG ); # Since doesn't work as expected!
      $SIG{$sig} = __PACKAGE__ . "::_dbug_trap_die_call";

   } elsif ( $sig eq "__WARN__" ) {
      $SIG{$sig} = __PACKAGE__ . "::_dbug_trap_warn_call";
   }

   return (1);    # Signal trapped ...
}


=item DBUG_TRAP_SIGNAL ( $signal, $action [, @forward_to] )

This function instructs I<DBUG> to trap the requested signal and write the
event to B<fish>.  If the signal name isn't in the %SIG hash, or the I<$action>
is invalid, then the request will be ignored!  Just be warned that not all
signals are trappable, and the list of signals may vary per OS.  Also note that
if the untrapped signal causes your program to terminate, any clean up done in
any B<END> blocks will also be ignored.

This signal is trapped even when B<fish> is turned off.  So the behavior of
your program doesn't change when B<fish> is turned on and off.  Except that
nothing is writen to B<fish> when B<fish> is turned off.

If called multiple times for the same signal, only the info for the last time
called is active.  It returns B<1> if the signal is now trapped or removed.
It returns B<0> if it had issues that prevented it from taking the requested
action against the signal.

Never call this function in a BEGIN block of code.  If you do so and hit
compile time issues, it can make your life very difficult trying to debug
things.

The I<$action> flag tells what this module is to do with this signal once it
is trapped and logged to B<fish>.  See below for this list of valid action
constants!  If the action is a negative value, it will call abs() before
it's validated.

=over 4

B<DBUG_SIG_ACTION_REMOVE> - Remove this I<$signal> from the list of signals
trapped.  Then restore $SIG{$signal} to it's original setting.  It does
nothing if the signal wasn't trapped by this module.

B<DBUG_SIG_ACTION_EXIT13> - Exit your program with the status of B<13>.
(Recommended for most signals.)

B<DBUG_SIG_ACTION_EXIT_SIGNUM> - Exit your program with the signal number
associated with the trapped signal as your exit status.  For signals DIE
and WARN, they will exit with B<240>/B<241> since they have no signal numbers!

B<DBUG_SIG_ACTION_DIE> - Call B<die>, it's trappable by I<eval> or
I<try/catch>.  (Recommended for signal DIE, using anything else for DIE could
break a lot of code.)

B<DBUG_SIG_ACTION_LOG> - Just log to B<fish> and return control to your code.
(Recommended for signal WARN)  Doesn't work for signal DIE, so can't use this
action to try to avoid the need for I<eval> or I<try/catch> blocks in your code.

=back

Just be aware that trapping certain signals and returning control back to your
program can sometimes cause strange behavior.

If action B<DBUG_SIG_ACTION_DIE> was used for your B<non-die> signal, it will
also call B<die>'s list of functions if B<die> was also trapped by this module.
But if you trap B<die> outside of this module this may trigger an unexpected
duplicate call to your custom B<die> routine.  So in this case it's best to
leave B<die> untrapped or trapped via this module as well.

If you provided I<@forward_to> it will assume you wish to call those function(s)
in the order specified after the signal has been logged to fish, but before the
specified I<$action> is taken.  This array may contain zero or more entries in
it!  Each entry in this array may be a reference to a function or a fully
qualified function name as a string.

When called, these functions will be passed one argument.  For most signals its
the name of the trapped signal.  But if called by trapping B<DIE> or B<WARN>,
it is the message printed by die or warn.  Just be aware that calls to die and
warn with multiple arguments have them joined together before the signal is
generated.  Any return value will be ignored.

But what happens if you call B<die> in one of these I<forward_to> functions?  In
that case the die request is ignored.  It's treated as an instruction to the
signal handler that it is to stop calling additional I<forward_to> function(s)
in this list.  It will not override the action selected.  If you really want
to terminate your program in one of these functions, write your message to
STDERR and call B<exit> or I<DBUG_LEAVE> instead!

NOTE: If you really, really want B<DBUG_SIG_ACTION_LOG> to work for B<die>,
see module L<Fred::Fish::DBUG::SignalKiller> and immediately forget you asked
about this.

=cut

# ==============================================================
sub DBUG_TRAP_SIGNAL
{
   my $sig    = uc (shift || "");   # The signal name, not the number!
   my $action = abs (shift || DBUG_SIG_ACTION_UNKNOWN);
   my @funcs  = @_;

   # Named after the function ...
   my $clr = "::DBUG_TRAP_SIGNAL";

   # Reset if a non-numeric action was given ... (to avoids warnings!)
   $action = DBUG_SIG_ACTION_UNKNOWN  unless ( $action =~ m/^\d+$/ );

   my $status = 0;   # Assume failure ...

   if ( $sig eq "DIE" || $sig eq "WARN" ) {
      $sig = "__${sig}__";    # Convert to __DIE__ or __WARN__.
   }

   # Did we ask to remove any previousy trapped signal ???
   if ( $action == DBUG_SIG_ACTION_REMOVE ) {
      if ( exists $dbug_signal_vars{forward_signals}->{$sig} ) {
         $SIG{$sig} = $dbug_signal_vars{original_signal_action}->{$sig};
         delete $dbug_signal_vars{forward_signals}->{$sig};
         delete $dbug_signal_vars{original_signal_action}->{$sig};
         delete $dbug_signal_vars{die_trapped}  if ( $sig eq "__DIE__" );
         $status = 1;   # Successfully removed the trapped signal!
      } else {
         on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_WARN, $clr,
                                 "The signal [%s] wasn't already trapped! %s",
                                 $sig, on_dbug_called_by (0) );
      }
      return ( $status );
   }

   # TO DO: Figure out a way to set this die action flag dynamically to 1 or 2!
   my $context = 2;   # Should be:  1 or 2 ...  See @die_action_msg for meaning!

   my $res = -1;   # An invalid action requested ...
   if ( $action == DBUG_SIG_ACTION_EXIT13      ||
        $action == DBUG_SIG_ACTION_EXIT_SIGNUM ||
        $action == DBUG_SIG_ACTION_LOG         ||
        $action == DBUG_SIG_ACTION_DIE ) {
      $res = _dbug_log_signal ($sig, $action, $context, @funcs);
   }

   if ( $res == -2 ) {
      on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_WARN, $clr,
                              "No such context [%s] for signal [%s] %s",
                              $action, $sig, on_dbug_called_by (0) );
   } elsif ( $res == -1 ) {
      on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_WARN, $clr,
                              "No such action [%s] for signal [%s] %s",
                              $action, $sig, on_dbug_called_by (0) );
   } elsif ( $res == 0 ) {
      on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_WARN, $clr,
                              "No such signal [%s] %s",
                              $sig, on_dbug_called_by (0) );
   } else {
      $status = 1;    # Success!
      my $ref = $dbug_signal_vars{forward_signals}->{$sig};
      $ref->{SAVE_SIG} = $SIG{$sig};
      $dbug_signal_vars{die_trapped} = 1  if ( $sig eq "__DIE__" );
   }

   return ( $status );
}


=item DBUG_FIND_CURRENT_TRAPS ( $signal )

This function tells if the requested I<$signal> is currently being trapped by
this module via I<DBUG_TRAP_SIGNAL> or not.

It can return one or more values:  ($action_taken [, $func1 [, $func2 [, ...]]])

If the signal isn't being trapped by this module it returns (undef).

If the signal is being trapped, but not forwarded it returns ($action_taken).
As an FYI, no valid action has a value of zero.

Otherwise it returns the I<$action_taken> and the list of functions it is
scheduled to call if the signal gets trapped.

But if called in scalar mode it just returns I<$action_taken> and tosses the
list of functions.

Each function will be returned as a B<CODE> reference.  Even if it was
originally passed to I<DBUG_TRAP_SIGNAL> as a string containing the function
to call.

If someone reset $SIG{$signal} manually, this function will detect that and
return (-1 * $action) for the action.  To make it easy to detect this problem.

=cut

# ==============================================================
sub DBUG_FIND_CURRENT_TRAPS
{
   my $sig = uc (shift || "");    # The signal name, not the number!

   if ( $sig eq "DIE" || $sig eq "WARN" ) {
      $sig = "__${sig}__";        # Convert to __DIE__ or __WARN__.
   }

   my $ref = $dbug_signal_vars{forward_signals}->{$sig};

   # If the signal wansn't trapped by this module ...
   return (0)   unless (defined $ref);

   # Both NAME & FUNC are always populated!
   my $act  = $ref->{ACTION};
   my $func = $ref->{FUNC};       # As an array of code referece ...
 # my $name = $ref->{NAME};       # As an array of strings ...

   # Did someone redirect where $SIG{$sig} pointed to???
   my $s = $SIG{$sig} || "";
   $act = -$act  if ( $s ne $ref->{SAVE_SIG} );

   return ($act)  unless (defined $func);

   return (wantarray ? ($act, @{$func}) : $act);
}


=item DBUG_DIE_CONTEXT ( )

This is a helper method to I<DBUG_TRAP_SIGNAL>.  For use when your custom die
routine(s) are called by the signal handler on a die request.  You call this
method for the context of the die request being handled.

It returns ( $fish_managed, $eval_trap, $original_signal, $rethrown, $die_action ).

If called in scalar mode it returns ( $fish_managed ).

=over 4

I<$fish_managed> - A boolean flag that tells if F<Fred::Fish::DBUG> managed
the call to your custom die function via a trapped B<__DIE__> signal.

I<$eval_trap> - Boolean value telling if this call to B<die> is going to be
trapped by an B<eval> block of code and/or a B<try/catch> block of code.
Otherwise it is false if it will be terminating your program when you return
to the signal handler.  It has no way of telling what the caller will do once
it catches the result.

I<$original_signal> - Tells which signal triggered the call to die.  If a
non-die signal was trapped using action DBUG_SIG_ACTION_DIE, it returns the
name of the trapped signal.  It returns B<__DIE__> if triggered directly.
Otherwise it returns the empty string if the call wasn't managed by B<fish>.

I<$rethrown> - A boolean flag that attempts to detect if your code caught a
previous call to B<die> in an B<eval> or B<try> block and then called B<die>
again with the same mesage.  It's set to B<1> if the previous B<die message>
was the same as the current B<die message>.  Else it's set to B<0>.  So if
you change the messsage before rethrowing the error again, this flag can't
help you.  Many times you'd like to do nothing on a rethrown die signal.

I<$die_action> - A code that tells what the die handler will do when it catches
any die thrown by your custom function.  B<1> - Die is ignored.  B<2> - Tells
the DIE handler not to call any more custom DIE function(s).  B<0> - The context
function doesn't know the answer.

=back

=cut

# ==============================================================
# $in_eval flag doesn't count the eval block in _dbug_forward_trapped_signal().
# Since that eval block controls what happens if your custom routine
# calls die itself!

sub DBUG_DIE_CONTEXT
{
   # Only set in _dbug_trap_die_call() before calling the custom functions.
   my $managed    = $dbug_signal_vars{die_context_managed} ? 1 : 0;
   my $in_eval    = $dbug_signal_vars{die_context_eval};
   my $sig        = $dbug_signal_vars{chained_die} || ($managed ? "__DIE__" : "");
   my $rethrown   = $dbug_signal_vars{same_die_message} || 0;
   my $die_action = $dbug_signal_vars{die_context_die};

   # Perl's special variable for Current State of the Interpreter.
   # $^S = (undef - parsing, 1 - in an eval block, 0 - otherwise)
   # Only used if $managed is "0"!  So OK if detecting the call
   # to this function was inside an eval/try block of code!
   $in_eval = $^S  unless ( defined $in_eval );

   # Rule to use if not managing the die request ...
   $die_action = 0   unless ( $managed );

   return ( wantarray ? ( $managed, $in_eval, $sig, $rethrown, $die_action ) : $managed );
}


# ====================================================================
# Undocumented signal handling functions ...
# Never called directly by anyone's code ...
# --------------------------------------------------------------------
# "$^S" - Perl's special var for Current State of the Interpreter.
# $^S = (undef - parsing, 1 - in an eval, 0 - otherwise)
# We may have to test this var in the future for DIE & WARN traps
# since both signals can be triggered during the parsing phase
# where maybe these 2 traps shouldn't be doing anything?
# Need to experiment with it a bit before ever using this var.
# So trapping these signals in a BEGIN block might be problematic
# at times.
# ====================================================================

#---------------------------------------------------------------------
# Generic TRAP function for DBUG (can't use for __DIE__ or __WARN__!)
# Perl calls it like  ==>
#              Fred::Fish::DBUG::Signal::_dbug_normal_signals ( $signal );
# Do not call it directly from your code!
#---------------------------------------------------------------------
# On UNIX, the trapped signal call is always wrapped by an "eval" block!
# The same is true on Windows when not called in hack mode for self tests!
# This affects how _dbug_trap_die_call() will handle things.
#---------------------------------------------------------------------
sub _dbug_normal_signals
{
   my $sig          = shift;              # The Signal Name in upper case!
   local $SIG{$sig} = "IGNORE";           # Prevents recursive signals!

   my $signal_msg = "Signal \"${sig}\" has been trapped and logged!" . on_dbug_called_by (0, 0);

   my $sig_info = $dbug_signal_vars{forward_signals}->{$sig};

   unless (defined $sig_info) {
      local $SIG{__WARN__} = "IGNORE";
      warn ($signal_msg . "\n",
            "But an improper hack of the DBUG module's Signal Handling has been detected.\n",
            "Aborting your program with an exit status of 13!\n");
      DBUG_LEAVE (13);
   }

   if ( DBUG_ACTIVE () ) {
      _dbug_stack_trace (1, $signal_msg);   # Writes stack to INFO level
   } else {
      on_dbug_hack (pause => 0, \&on_dbug_print_pkg_tag, DBUG_FILTER_LEVEL_INFO, "::${sig}", $signal_msg);
   }

   if ( $sig_info->{CONTEXT} ) {
      local $dbug_signal_vars{chained_die} = ${sig};
      my $func = $sig_info->{FUNC};
      _dbug_forward_trapped_signal ( $sig, "", $sig_info->{CONTEXT}, @{$func} );
   }

   # What to do after processing the signal ...
   if ( $sig_info->{ACTION} == DBUG_SIG_ACTION_EXIT13 ||
        $sig_info->{ACTION} == DBUG_SIG_ACTION_EXIT_SIGNUM ) {
      DBUG_LEAVE ( $sig_info->{EXIT} );

   } elsif ( $sig_info->{ACTION} == DBUG_SIG_ACTION_LOG ) {
      return;

   } elsif ( $sig_info->{ACTION} == DBUG_SIG_ACTION_DIE ) {
      local $dbug_signal_vars{chained_die} = ${sig};
      _dbug_turn_off_end_while_dying (0);
      die ("Calling die due to caught Signal [$sig]\n");
      return;
   }

   # Should never get here ...
   on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_WARN,
                  "Unexpected Signal Action Specified for signal %s! (%d)\n%s",
                  $sig, $sig_info->{ACTION}, "  Just logging it!");

   return;
}



# --------------------------------------------------------------
# Can only be called when $SIG{__WARN__} was trapped & triggered!
# Doesn't do a stack trace.
# --------------------------------------------------------------

sub _dbug_trap_warn_call
{
   my $msg = shift;

   local $SIG{__WARN__} = "IGNORE";

   my $sig_info = $dbug_signal_vars{forward_signals}->{__WARN__};

   my $level = DBUG_FILTER_LEVEL_WARN;

   # Write the warning to the screen?
   if ( $sig_info->{ACTION} != DBUG_SIG_ACTION_DIE ) {
      # unless ( DBUG_EXECUTE ( $level ) == -1 ) {
         print STDERR $msg;
      # }
   }

   # Check if the warning message already tells where it came from!
   # If not, we'll only add it to the end of the messge written to fish!
   my ($line, $filename) = (caller(0))[2,1];
   my $extra = "at ${filename} line ${line}.";
   if ( $msg =~ m/ at (.+) line ${line}[.]/ && $1 eq $filename) {
      $extra = "";    # No need to repeat this info!
   }

   on_dbug_hack (pause => 0, \&on_dbug_print_pkg_tag, $level, "::__WARN__", "%s%s", $msg, $extra);

   if ( $sig_info->{CONTEXT} ) {
      local $dbug_signal_vars{chained_die} = "__WARN__";
      my $funcs = $sig_info->{FUNC};
      _dbug_forward_trapped_signal ( "__WARN__", $msg, $sig_info->{CONTEXT}, @{$funcs} );
   }

   # What to do after processing the signal ...
   if ( $sig_info->{ACTION} == DBUG_SIG_ACTION_EXIT13 ||
        $sig_info->{ACTION} == DBUG_SIG_ACTION_EXIT_SIGNUM ) {
      DBUG_LEAVE ( $sig_info->{EXIT} );

   } elsif ( $sig_info->{ACTION} == DBUG_SIG_ACTION_LOG ) {
      return;

   } elsif ( $sig_info->{ACTION} == DBUG_SIG_ACTION_DIE ) {
      local $dbug_signal_vars{chained_die} = "__WARN__";
      my $stack = "Called \"warn\" for a stack trace ... " . on_dbug_called_by(1);
      _dbug_stack_trace (1, $stack);
      _dbug_turn_off_end_while_dying (1);
      die ( $msg );
      return;
   }

   # Should never get here ...
   on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_WARN,
                   "Unexpected Signal Action Specified for signal %s! (%d)\n%s",
                   "__WARN__", $sig_info->{ACTION}, "  Just logging it!");

   return;
}


# --------------------------------------------------------------
# Can only be called when $SIG{__DIE__} was trapped & triggered!
# Other signals can get here indirectly when using the DIE action.
# --------------------------------------------------------------
# Question:  Do we really want to call the custom forward function(s)
#            if "die" was called inside an "eval" block?
#
#            Right now the answer is "YES".
#            DBUG_DIE_CONTEXT() was added to allow the developer to
#            decide if this is the right answer or not.
# --------------------------------------------------------------

sub _dbug_trap_die_call
{
   my $msg = shift;    # Always ends in "\n"!

   local $SIG{__DIE__} = "IGNORE";

   # So fish won't try to rebalance fish while processing the die request ...
   my $runWhenOutOfScope = Perl::AtEndOfScope->new ( \&on_set_global_var,
                         'skip_eval_fix', on_get_global_var ('skip_eval_fix') );
   on_set_global_var ('skip_eval_fix', 1);

   my $sig_info = $dbug_signal_vars{forward_signals}->{__DIE__};
   unless ( $sig_info ) {
      my %tmp;
      $tmp{ACTION} = DBUG_SIG_ACTION_DIE;
      $sig_info = \%tmp;
   }

   my $funcs = $sig_info->{FUNC};

   my $trapped_by_eval = 1;     # Assume true for now ...
   my $rethrown = 0;            # Assume not trapping a rethrown exception.
   my $stack_msg = "Called \"die\" for a stack trace ... " . on_dbug_called_by (1);

   # Was this call triggered via another signal handler calling die?
   if ( $dbug_signal_vars{chained_die} ) {
      # Set so when the "eval" block around the original signal catches
      # this "die", it will still remember next time that the request is
      # a duplicate of this one and not repeat any work when it rethrows
      # the "die" again!  (IE print the stack trace or calling the custom
      # "die" function(s) a 2nd time for the same event.)
      $dbug_signal_vars{expect_duplicate_rethrown_request} = 1;
      delete $dbug_signal_vars{last_die_message};

      # Stack trace was already printed out by the other signal calling die ...
      $trapped_by_eval = $^S;    # Perl's special var tells if trapped by eval!

   # Was "die" called again when a "eval" block rethrew the original forwarded
   # die message from another signal again?
   # If so, we don't want to forward things to the custom functions again!
   } elsif ( $dbug_signal_vars{expect_duplicate_rethrown_request} ) {
      delete $dbug_signal_vars{expect_duplicate_rethrown_request};

      # Just verifying my assumption ...
      $rethrown = ($msg eq $dbug_signal_vars{last_die_message} ) ? 1 : 0;

      my $prt_sts;       # Unknown state ...
      if ( $rethrown ) {
         $funcs = undef;
         $prt_sts = 0;   # Turn it off ...
      }

      on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_INTERNAL, "%s\n%s",
                              "Caught the expected rethrown die request!",
                              $rethrown ? "The messages were the same."
                                        : "The messages were different!");

      # Should we turn printing off?  Or leave it in it's current state?
      $trapped_by_eval = on_dbug_hack ( on => $prt_sts, \&_dbug_stack_trace, 1, $stack_msg );

   # Did the normal die get trapped by an 'eval' and rethrown again with
   # the same message?  This is not 100% reliable since people tend to
   # rethrow the 'die' with a new message in their own code!
   } elsif ( $dbug_signal_vars{last_die_message} &&
             $dbug_signal_vars{last_die_message} eq $msg ) {
      $rethrown = 1;

      # Do we want to call the custom functions on a rethrow ???
      # Currently using DBUG_DIE_CONTEXT() so the user can decide for himself!
      # $funcs = undef;         # Uncomment if the answer is no!

      # Assumes we don't want a stack trace again ...
      $trapped_by_eval = $^S;    # Perl's special var tells if trapped by eval!

   # Just a normal 1st time call to die!
   } else {
      $trapped_by_eval = _dbug_stack_trace (1, $stack_msg);
   }

   # ------------------------------------------------------------------
   # Write the die messsage to fish ...
   # ------------------------------------------------------------------
   if ( $rethrown == 0 ) {
      on_dbug_hack (pause => 0, \&on_dbug_print_pkg_tag, DBUG_FILTER_LEVEL_ERROR,  "::Signal::__DIE__", $msg);
   }

   # So can detect if die was trapped by an eval stmt & rethrown again!
   $dbug_signal_vars{last_die_message} = $msg;

   # ------------------------------------------------------------------
   # Let's call the custom die routines ...
   # And manage future calls to DBUG_DIE_CONTEXT() by any of them!
   # ------------------------------------------------------------------
   if ( $funcs && $sig_info->{CONTEXT} ) {
      # {chained_die} was set elsewhere if needed ...
      local $dbug_signal_vars{die_context_managed} = 1;
      local $dbug_signal_vars{same_die_message} = $rethrown;

      my $context_action = $trapped_by_eval;
      if ( $sig_info->{ACTION} == DBUG_SIG_ACTION_EXIT13 ||
           $sig_info->{ACTION} == DBUG_SIG_ACTION_EXIT_SIGNUM ) {
         $context_action = 0;     # Ignore any eval/try attempts ...
      }
      local $dbug_signal_vars{die_context_eval} = $context_action;

      # Must either be 1 or 2 in this instance!
      local $dbug_signal_vars{die_context_die} = $sig_info->{CONTEXT};

      _dbug_forward_trapped_signal ( "__DIE__", $msg, $sig_info->{CONTEXT}, @{$funcs} );
   }

   # ------------------------------------------------------------------
   # What to do after processing the signal ...
   # ------------------------------------------------------------------
   if ( $sig_info->{ACTION} == DBUG_SIG_ACTION_EXIT13 ||
        $sig_info->{ACTION} == DBUG_SIG_ACTION_EXIT_SIGNUM ) {
      print STDERR $msg;
      DBUG_LEAVE ( $sig_info->{EXIT} );

   } elsif ( $sig_info->{ACTION} == DBUG_SIG_ACTION_LOG ) {
      if ( $dbug_signal_vars{LOG_NOW_WORKS_IN_DIE} ) {
         delete $dbug_signal_vars{LOG_NOW_WORKS_IN_DIE};
         print STDERR join ("", $msg);
         $@ = "";    # So the catch block of eval or try won't be triggered!
         return;     # Returns control to program ignoring "eval"/"try" logic.
      }

      unless ( $rethrown ) {
         print STDERR
               "Ha ha!  I already told you using DBUG_SIG_ACTION_LOG for trapping __DIE__\n",
               "doesn't work!  It still calls die anyway!\n";
      }
      _dbug_turn_off_end_while_dying (2);
      return;           # This return triggers an automatic die!

   } elsif ( $sig_info->{ACTION} == DBUG_SIG_ACTION_DIE ) {
      _dbug_turn_off_end_while_dying (2);

      # This die will write the die message to the screen!
      # Unless it's trapped by an eval ...
      die ( $msg );
   }

   # Should never get here ...
   on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_WARN,
                   "Unexpected Signal Action Specified for signal %s! (%d)\n%s",
                   "__DIE__", $sig_info->{ACTION}, "  Just logging it!");

   return;
}

# --------------------------------------------------------------------
# Prints out a stack trace (Not necessarily the fish function trace.)
# Never called when __WARN__ is trapped.
# --------------------------------------------------------------------
# Returns: The numer of eval's detected in the stack!  (>= 0)
# --------------------------------------------------------------------
sub _dbug_stack_trace
{
   my $skip = shift;     # How many functions on the stack to skip over ...
   my $msg  = shift;     # What message to start the stack trace with ...

   my $eval_found = 0;    # Assume not trapped by an eval block.

   # Filter based on INFO level ...
   my $level = DBUG_FILTER_LEVEL_INFO;

   # Color based on INTERNAL level ...
   my @colors = on_get_filter_color (DBUG_FILTER_LEVEL_INTERNAL);

   my $print_flg = on_filter_on ( $level );

   on_dbug_print_pkg_tag ( $level, $msg )   if ( $msg );

   # Not using DBUG_PRINT on purpose ...
   my ($c, $idx) = ("", $skip + 1);
   while ( $c = (caller (${idx}++))[3] ) {
      on_printing $colors[0], on_indent ("Stack Trace"), " --> $c ()", $colors[1], "\n"  if ( $print_flg );
      ++$eval_found   if ( $c eq "(eval)" );  # Eval block in stack found!
   }

   on_printing $colors[0], on_indent ("Stack Trace"), " --> main ()", $colors[1], "\n"  if ( $print_flg );

   return ($eval_found);    # Count of eval levels detected ...
}


# =============================================================================
# Calls all the custom signal functions.
# But what happens if the custom signal function itself calls die?
# $die_action tells which @die_action_msg to use ... (1 or 2)

# Using action "3" causes issues, so no longer supported!

my @die_action_msg = ( "One of the custom signal functions called die!",
                       "But we're ignoring any die requests here.",
                       "So we're not calling the remaining custom function(s)!",
                     # "So we're honoring the request by rethrowing the error."
                     );

sub _dbug_forward_trapped_signal
{
   my $sig        = shift;     # The current signal being thrown!
   my $msg        = shift;     # Only provided with DIE/WARN signals!
   my $die_action = shift;     # Action/Context if die is called in custom signal function.
   my @func_lst   = @_;        # The list of functions to call ... shouldn't be empty.

   # Did someone try to loop recursively back to me again ???
   return    if ( $dbug_signal_vars{recursion} );     # Yes ...

   ++$dbug_signal_vars{recursion};

   # Determine which value to use for the arguments ...
   my $arg = $msg ? $msg : $sig;

   # Build an alternate stack so the forward functions can't mess fish up!
   my @alt_stack;
   my $func = sub { my $lvl = shift; foreach (1..$lvl) { DBUG_ENTER_BLOCK ("***** Fish Mistake in Custom Signal function *****"); } return; };
   on_dbug_hack (on => 0, who_called => 0, functions => \@alt_stack, $func, on_dbug_level() + 1);

   foreach my $fn ( @func_lst ) {
      eval {
         local $SIG{__DIE__} = "DEFAULT";
         on_dbug_hack ( who_called => 0, \&DBUG_ENTER_BLOCK,
                      __PACKAGE__ . "::Forwarding-Trapped-Signal-${sig}" );

         # Indirectly calling the custom signal function with own fish stack ...
         my @own_stack = @alt_stack;
         my $stop = on_dbug_hack ( functions => \@own_stack, $fn, $arg );

         DBUG_VOID_RETURN ();
         # last  if ( $stop );
      };

      if ( $@ ) {
         on_dbug_print_pkg_tag ( DBUG_FILTER_LEVEL_INTERNAL, "%s\n%s\n%s",
                         $die_action_msg[0], $die_action_msg[$die_action], $@ );
         DBUG_CATCH ();

         next   if ( $die_action == 1 );    # Ignore the die!
         last;                              # Skip remaining custom funcs.
      }
   }     # End foreach $fn loop ...

   --$dbug_signal_vars{recursion};

   return;
}


=back

=head1 CREDITS

Thanks to Fred Fish for developing the basic algorithm and putting it into the
public domain!  Any bugs in its implementation are purely my fault.

=head1 SEE ALSO

L<Fred::Fish::DBUG> The controling Fred Fish DBUG module.

L<Fred::Fish::DBUG::ON> The live version of the DBUG module.
Used to log fish calls made by this module.

L<Fred::Fish::DBUG::OFF> The stub version of the DBUG module.

L<Fred::Fish::DBUG::TIE> - Allows you to trap and log STDOUT/STDERR to B<fish>.

L<Fred::Fish::DBUG::SignalKiller> - Allows you to implement action
DBUG_SIG_ACTION_LOG for B<die>.  Really dangerous to use.  Will break most
code bases.

L<Fred::Fish::DBUG::Test> - A L<Test::More> wrapper to redirect test results to
B<fish>.

L<Fred::Fish::DBUG::Tutorial> - Sample code demonstrating using DBUG module.

=head1 COPYRIGHT

Copyright (c) 2007 - 2025 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# ============================================================
#required if module is included w/ require command;
1;
 
