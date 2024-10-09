##
## Stub module to do common bookkeeping performed for all the test cases ...
## So that the t/*.t programs don't get cluttered with these common functions!
##

package helper1234;

use strict;
use warnings;

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Test::More 0.88;
use File::Basename;
use File::Spec;

$VERSION = "2.07";
@ISA = qw( Exporter );

@EXPORT = qw( get_fish_state
              bail
              dbug_active_ok_test
              get_fish_log
              get_delay_file
              get_fish_module
              find_fish_users
              get_fish_opts
              get_called_by_code_ref
              print_stack_trace
              is_hires_supported   is_threads_supported   is_fork_supported
              test_fish_level
              test_fish_level_no_warn
              test_func_name
              test_func_name_no_warn
              test_mask_return
              test_mask_args
              simulate_windows_signal
              is2
              ok2 ok3 ok9
              isa_ok2 isa_ok3
            );

@EXPORT_OK = qw( );

# The name of the log file to use ...
my $fish_file;
my $delay_file;

# The use/import options for the module ...
my @fish_opts;

# -----------------------------------------------------------------------
# $ENV{FISH_OFF_FLAG}:
#     -1 --- use Fred::Fish::DBUG qw / off /;
#      0 --- use Fred::Fish::DBUG qw / on /;   # with fish turned on ...
#      1 --- use Fred::Fish::DBUG qw / on /;   # with fish turned off ...
# -----------------------------------------------------------------------

sub get_fish_state
{
   if ( $ENV{FISH_OFF_FLAG} ) {
      return ( ($ENV{FISH_OFF_FLAG} < 0) ? -1 : 1 );
   }
   return (0);
}


# -----------------------------------------------------------------------
# Chooses between Fred::Fish::DBUG::ON & Fred::Fish::DBUG::OFF ...
# Also calculates the default name to use for the fish log ...
# -----------------------------------------------------------------------
BEGIN
{
   $fish_file = $0;
   $fish_file =~ s/[.]t$//;
   $fish_file .= ".fish.txt";

   $fish_file = File::Spec->catfile (dirname ($fish_file), "fish", basename ($fish_file));

   my $num = (basename($0) =~ m/^(\d+)/) ? $1 : "0";
   $delay_file = File::Spec->catfile (dirname ($0), "fish", "delay_" . $num . ".txt");

   @fish_opts = qw / on /;

   if ( $ENV{FISH_OFF_FLAG} ) {
      unlink ( $fish_file );
      @fish_opts = qw / off /  if ( $ENV{FISH_OFF_FLAG} < 0 );
   }
   unlink ( $delay_file );

   # Can't use use_ok() here!  It messes the flow of the tests ...
   # use_ok ("Fred::Fish::DBUG", @fish_opts);

   # Let's source in the prefered version of the module ...
   eval "use Fred::Fish::DBUG qw / " . join (" ", @fish_opts) . " /";
   if ( $@ ) {
      done_testing ();
      BAIL_OUT ( "Module helper1234 can't load Fred::Fish::DBUG qw / " .
                 join (" ", @fish_opts) . " /" );
      exit (0);
   }
}

# -----------------------------------------------------------------------
# The current releases of the Fred::Fish::DBUG module doesn't auto-trap
# any signals.  So doing that here in such a way that if the caller
# sets them it won't override their earlier choices.
# Done here so I don't have to repeat this in all the test programs!
# -----------------------------------------------------------------------
BEGIN
{
   # Let's source in the Signal handler for the module ...
   eval "use Fred::Fish::DBUG::Signal";
   if ( $@ ) {
      done_testing ();
      BAIL_OUT ( "Module helper1234 can't load Fred::Fish::DBUG::Signal" );
      exit (0);
   }
}

BEGIN
{
   # Did someone aleady trap these signals?
   # An action of zero (0) means they are not currently trapped ...
   my ( $die_action,  @die_funcs )  = DBUG_FIND_CURRENT_TRAPS ( "__DIE__" );
   my ( $warn_action, @warn_funcs ) = DBUG_FIND_CURRENT_TRAPS ( "__WARN__" );

   unless ( $die_action ) {
      DBUG_TRAP_SIGNAL ("__DIE__", DBUG_SIG_ACTION_DIE, $SIG{__DIE__} );
   }
   unless ( $warn_action ) {
      DBUG_TRAP_SIGNAL ("__WARN__", DBUG_SIG_ACTION_LOG, $SIG{__WARN__} );
   }
}

END
{
   DBUG_ENTER_FUNC();
   DBUG_VOID_RETURN();
}

# -----------------------------------------------------------------------
# Non-exposed functions ...
# -----------------------------------------------------------------------
sub the_real_caller
{
   # Get the caller's filename & line number ...
   my @c = (caller(1))[1,2];
   diag ("  at $c[0] line $c[1].\n");
}

sub paused
{
   my $msg = shift;

   # Always paused when fish is turned off ...
   unless ( DBUG_ACTIVE () ) {
      if ( get_fish_state () == -1 ) {
         $msg = "OFF - " . $msg
      } else {
         $msg = "PAUSED - " . $msg
      }
   }

   return ($msg);
}


# -----------------------------------------------------------------------
# The exposed funtions ...
# -----------------------------------------------------------------------
sub bail
{
   my $msg = shift || "Unknown reason for bailing!";

   done_testing ();
   BAIL_OUT ( $msg );
   exit (0);
}

# -----------------------------------------------------------------------
sub dbug_active_ok_test
{
   if ( get_fish_state () == 0 ) {
      return ( DBUG_ACTIVE(), "Fish is turned ON." );
   } else {
      return ( ! DBUG_ACTIVE(), "Fish is turned OFF." );
   }
}

# -----------------------------------------------------------------------
sub get_fish_log
{
   return ( $fish_file );
}

sub get_delay_file
{
   return ( $delay_file );
}

# Returns the ON or OFF modue used for the spcified file.
sub get_fish_module
{
   my $mode = shift;    # Passed undef or __FILE__ ...
   $mode = __FILE__  unless ( defined $mode );     # helper1234.pm ...

   my ($module, $file) = Fred::Fish::DBUG::dbug_module_used ($mode);

   # ok2 ( $file eq $mode, "Selected file: $file  -->  $module" );

   return ( wantarray ? ($module, $file ) : $module );
}

sub find_fish_users
{
   my $opt = shift;

   my %h = Fred::Fish::DBUG::find_all_fish_users ();

   if ( $opt ) {
      $h{z_EXTRA_FILE} = (caller(0))[1] . " (IGNORE-ME)";
   }

   return ( %h );
}

sub get_fish_opts
{
   return ( @fish_opts );
}

sub get_called_by_code_ref
{
   return ( \&Fred::Fish::DBUG::dbug_called_by );
}

sub print_stack_trace
{
   my $msg = shift || "";

   # Not interested in the return value (# of evals deep)
   my $evl = Fred::Fish::DBUG::dbug_stack_trace ($msg);

   return;
}

# -----------------------------------------------------------------------
sub is_hires_supported
{
   return ( Fred::Fish::DBUG::dbug_time_hires_supported () );
}

sub is_threads_supported
{
   return ( Fred::Fish::DBUG::dbug_threads_supported () );
}

sub is_fork_supported
{
   return ( Fred::Fish::DBUG::dbug_fork_supported () );
}

# -----------------------------------------------------------------------
# This version gives warnings if the hint is used ...
sub test_fish_level
{
   my $hint = shift;   # Only OFF uses this optional hint!
   return ( Fred::Fish::DBUG::dbug_level ($hint) );
}

# This version doesn't give warnings if the hint is used ...
sub test_fish_level_no_warn
{
   my $hint = shift;   # Only OFF uses this optional hint!

   my $lvl = Fred::Fish::DBUG::dbug_level ();
   if ( $lvl == -1 && (defined $hint) && get_fish_state () == -1 ) {
      $lvl = $hint;
   }

   return ( $lvl );
}

# This version gives warnings if the hint is used ...
sub test_func_name
{
   my $hint = shift;   # Only OFF uses this optional hint!
   return ( Fred::Fish::DBUG::dbug_func_name ($hint) );
}

# This version doesn't give warnings if the hint is used ...
sub test_func_name_no_warn
{
   my $hint = shift;   # Only OFF uses this optional hint!

   my $name = Fred::Fish::DBUG::dbug_func_name ();
   if ( (! defined $name) && (defined $hint) && get_fish_state () == -1 ) {
      $name = $hint;
   }

   return ( $name );
}

# Hint is used unless fish is turned on ...
sub test_mask_return
{
   my $hint = shift;   # Only OFF uses this optional hint!
   return ( Fred::Fish::DBUG::dbug_mask_return_counts ($hint) );
}

# Hint is used unless fish is turned on ...
sub test_mask_args
{
   my $hint = shift;   # Only OFF uses this optional hint!
   return ( Fred::Fish::DBUG::dbug_mask_argument_counts ($hint) );
}

# -----------------------------------------------------------------------
# It looks like Windows can't send a signal to itself via kill!
# So the test here is mostly just a cheat for windows!
# The cheat is to call the signal function directly instead
# of as a trapped signal!
# It's wrapped in an eval the way it would behave if it really
# was a trapped signal.
#
# NOTE: DIE/WARN don't behave like the other signals.  They don't
#       get surrounded by "eval" like the other signals do.
#       So just included here to allow a single point of contact.
#
# NOTE: Only calls signals that have been redirected.  If its not
#       redirected, it's treated as an error!

sub simulate_windows_signal
{
   my $sig = shift;   # Ex:  INT, ...  Not the numeric values ...
   my $msg = shift || "No message provided for $sig!\n";;

   # These two signals don't get surrounded by "eval"!
   my $special_sig = ( $sig eq "__DIE__" || $sig eq "__WARN__" );
 
   my $func;   # Will always be a code reference if set.

   if ( $SIG{$sig} ) {
      if ( ref ($SIG{$sig}) eq "CODE" ) {
         $func = $SIG{$sig};

      } elsif ( $SIG{$sig} =~ m/^\s*(\S+)::([^:\s]+)\s*$/ ) {
         my ($type, $method) = ($1, $2);
         $func = $type->can ($method);
      }
   }

   my $called = 0;
   if ( $func ) {
      DBUG_PRINT ("INFO",
                  "Using a cheat for %s instead of sending a real signal! (%s)",
                  $sig, $func);   # Auto converts the code ref into it's name.
      $called = 1;

      # These 2 signals are not simulated since I can trigger them for real ...
      if ( $sig eq "__WARN__" ) {
         warn ( $msg );
         return ( $called );
      } elsif ( $sig eq "__DIE__" ) {
         die ( $msg );
         return ( $called );   # Should never get here ...
      }

      # Simulates how the stack trace looked during my unix testing.
      # when triggered by 'kill($sig,$$);' ...
      eval { $func->( $sig ); };   # All other signals ...
      die ( $@ )   if ( $@ );

   } else {
      ok2 (0, "Called the ${sig} signal cheat successfully!");
   }

   return ( $called );
}

# -----------------------------------------------------------------------
sub is2
{
   my $got      = shift;
   my $expected = shift;
   my $msg      = shift;

   my $res = is ($got, $expected, $msg);
   if ( $res ) {
      DBUG_PRINT ("OK2", "[$msg]");
   } else {
      DBUG_PRINT ("NOT OK2", "[%s]\n#        got: [%s]\n#   expected: [%s]\n",
                  $msg, $got, $expected);
      the_real_caller ();
   }

   return ( $res );
}

# -----------------------------------------------------------------------
sub ok2
{
   my $status = shift || 0;
   my $msg    = shift;

   $msg = paused ($msg);

   my $lbl = ($status) ? "OK2" : "NOT OK2";
   DBUG_PRINT ($lbl, "[%s], [%s]", $status, $msg);

   my $res = ok ( $status, $msg );
   the_real_caller ()  unless ( $res );

   return ( $res );
}

sub ok3
{
   DBUG_ENTER_BLOCK ("Test::More::ok", @_);
   my $status = shift || 0;
   my $msg    = shift;

   $msg = paused ($msg);

   my $res = ok ( $status, $msg );
   the_real_caller ()  unless ( $res );

   DBUG_RETURN ($res);
}

# A variant of ok2() above that doesn't use DBUG_PRINT().
# For use when option "who_called => 1" is in use.  So it tells
# who called ok9() instead of the location of DBUG_PRINT call.
sub ok9
{
   my $status = shift || 0;
   my $msg    = shift;

   $msg = paused ($msg);

   my $res = ok ( $status, $msg );
   the_real_caller ()  unless ( $res );

   my $lbl = ($res) ? "OK9" : "NOT OK9";

   # Only do this work if we're actually going to write to fish!
   # Does an abreviated DBUG_PRINT();
   if ( DBUG_EXECUTE ($lbl) ) {
      my $fh = DBUG_FILE_HANDLE ();
      my $str = Fred::Fish::DBUG::dbug_indent ( "" );
      if ( $fh && $str ) {
         printf $fh ("%s%s: [%d], [%s]\n", $str, $lbl, $res, $msg);

         # Who called ok9() ??
         my $who = Fred::Fish::DBUG::dbug_called_by (1, 1);

         my $len = length ($lbl);
         $lbl = " "x${len};
         printf $fh ("%s%s: %s\n", $str, $lbl, $who);
      }
   }

   return ( $res );
}

# -----------------------------------------------------------------------
sub isa_ok2
{
   my ( $obj, $ref, $msg ) = ( shift, shift, shift );

   my $res = isa_ok ( $obj, $ref, $msg );
   the_real_caller ()  unless ( $res );

   my $lbl = ($res) ? "ISA_OK2" : "NOT ISA_OK2";

   # So DBUG_PRINT() will match isa_ok()!
   if ( $msg ) {
      $msg = "'${msg}' isa '${ref}'";
   } elsif ( $obj && $res ) {
      $msg = "An object of class '" . ref ($obj) . "' isa '${ref}'";
   } elsif ( ref ($obj) ne "" ) {
      $msg = "A reference of type '" . ref ($obj) . "' isa '${ref}'";
   } elsif ( defined $obj ) {
      $msg = "The class (or class-like) '${obj}' isa '${ref}'";
   } else {
      $msg = "undef isa '${ref}'";
   }
   DBUG_PRINT ( $lbl, "[%d] [%s]", $res , $msg );

   return ( $res );
}

sub isa_ok3
{
   DBUG_ENTER_BLOCK ("Test::More::isa_ok", @_);
   my ( $obj, $ref, $msg ) = ( shift, shift, shift );
   my $res = isa_ok ( $obj, $ref, $msg );
   the_real_caller ()  unless ( $res );
   DBUG_RETURN ($res);
}

# ============================================================
#required if module is included w/ require command;
1;

