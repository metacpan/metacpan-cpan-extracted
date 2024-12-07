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
use Fred::Fish::DBUG::Test;

use File::Basename;
use File::Spec;

$VERSION = "2.09";
@ISA = qw( Exporter );

@EXPORT = qw( get_fish_state
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

   # Can't use dbug_use_ok() here!  It messes the flow of the tests ...
   # dbug_use_ok ("Fred::Fish::DBUG", @fish_opts);

   # Let's source in the prefered version of the module ...
   eval "use Fred::Fish::DBUG qw / " . join (" ", @fish_opts) . " /";
   if ( $@ ) {
      dbug_BAIL_OUT ( "Module helper1234 can't load Fred::Fish::DBUG qw / " .
                      join (" ", @fish_opts) . " /" );
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
      dbug_BAIL_OUT ( "Module helper1234 can't load Fred::Fish::DBUG::Signal" );
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

# -----------------------------------------------------------------------
# The exposed funtions ...
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

   # dbug_cmp_ok ( $file, 'eq', $mode, "Selected file: $file  -->  $module" );

   return ( wantarray ? ($module, $file ) : $module );
}

sub find_fish_users
{
   my $opt = shift;

   my %h = Fred::Fish::DBUG::find_all_fish_users ();

   if ( $opt ) {
      $h{z_EXTRA_FILE} = (caller(0))[1] . ' (IGNORE-ME)';
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
      dbug_ok (0, "Called the ${sig} signal cheat successfully!");
   }

   return ( $called );
}


# ============================================================
#required if module is included w/ require command;
1;

