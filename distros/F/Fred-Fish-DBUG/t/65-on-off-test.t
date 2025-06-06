#!/user/bin/perl

# Program:  65-on-off-test.t
# This test case makes sure using
#     Fred::Fish::DBUG::ON
# and
#     Fred::Fish::DBUG::OFF
# together in the same program doesn't break things!
# Can't push to CPAN if they don't play together!

use strict;
use warnings;

use File::Spec;
use Test::More;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

my $start_level;

sub my_warn
{
   dbug_ok (0, "There was an expected warning!  Check fish.");
}

sub func2
{
   DBUG_ENTER_FUNC (@_);
   DBUG_VOID_RETURN ();
}

my $fish_module;

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {     # Test # 2
      dbug_BAIL_OUT ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
                      join (" ", @opts) . " /" );
   }

   dbug_ok (1, "Used options qw / " . join (" ", @opts) . " /");

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
  }
}

BEGIN {
   # So can detect if the module generates any unexpected warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;
   my $lvl = ( get_fish_state () == -1 ) ? -1 : 1;

   DBUG_PUSH ( get_fish_log(), off => ${off} );

   my $module;

   # The two conflicted modules ...
   unless ( use_ok ("on_test") ) { # This module only uses Fred::Fish::DBUG::ON
      dbug_BAIL_OUT ( "Can't load the 'on_test' module!" );
   }
   $module = get_fish_module ();
   dbug_is ($module, $fish_module, "Selected correct module ($module vs $fish_module)");

   unless ( use_ok ("off_test") ) { # This module only uses Fred::Fish::DBUG:OFF
      dbug_BAIL_OUT ( "Can't load the 'off_test' module!" );
   }
   $module = get_fish_module ();
   dbug_is ($module, $fish_module, "Selected correct module ($module vs $fish_module)");

   $module = get_fish_module ( ON_FILE() );
   dbug_ok ( $module =~ m/::ON$/, "Statically linked to ON --> $module");
   $module = get_fish_module ( OFF_FILE() );
   dbug_ok ( $module =~ m/::OFF$/, "Statically linked to OFF --> $module");

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   dbug_is ($start_level, $lvl, "In the BEGIN block ...");   # Test # 2
   DBUG_PRINT ("PURPOSE", "\nJust verifying the we can use Fred::Fish::DBUG & Fred::Fish::DBUG::OFF together!\n.");
   func2();
   $lvl = test_fish_level ();
   dbug_is ($lvl, $start_level, "BEGIN Level Check Worked!");

   dbug_ok ( dbug_active_ok_test () );

   dbug_ok ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   my %usr = find_fish_users ();
   my $cnt = keys %usr;
   dbug_cmp_ok ($cnt, '==', 4, "Found ${cnt} users of DBUG (4).");

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   func2();
   my $lvl = test_fish_level ();
   if ( $start_level != $lvl ) {
      dbug_ok (0, "END Level Check Worked!");
   }

   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 4 ...

   DBUG_PRINT ("----", "%s", "="x70);
   dbug_ok (1, "Calling the ON Module ...");  # Test # 5 ...

   ON_PRINT1 (1, 2, 3);
   my @l = ON_PRINT2 (9, 8, 7);

   ON_BAD_SIGNAL ();
   ON_WARN_TEST ();

   DBUG_PRINT ("----", "%s", "="x70);
   dbug_ok (1, "Calling the OFF Module ...");  # Test # 6 ...

   OFF_PRINT1 (1, 2, 3);
   @l = OFF_PRINT2 (9, 8, 7);

   OFF_BAD_SIGNAL ();
   OFF_WARN_TEST ();

   DBUG_PRINT ("----", "%s", "="x70);
   dbug_ok (1, "Back to normal operation ...");  # Test # 7 ...

   here_is_one_long_function_name ();

   my $lvl = test_fish_level ();
   dbug_is ($lvl, $start_level, "MAIN Level Check Worked!");

   DBUG_FILTER ( DBUG_FILTER_LEVEL_INTERNAL );

   DBUG_PRINT ("----", "------------------------------------");
   trigger_test ( "INT", 0 );
   DBUG_PRINT ("----", "------------------------------------");
   trigger_test ( "__DIE__", 1, "Shall we die?" );
   DBUG_PRINT ("----", "------------------------------------");
   trigger_test ( "INT", 0 );
   DBUG_PRINT ("----", "------------------------------------");
   trigger_test ( "__DIE__", 0, "Shall we say good-bye?" );
   DBUG_PRINT ("----", "------------------------------------");

   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
sub trigger_test
{
   DBUG_ENTER_FUNC (@_);
   my $sig   = shift;
   my $allow = shift;          # Allow no-forward func?
   my $sMsg  = shift || $sig;  # The die/warn message.

   my ($act, @funcs) = DBUG_FIND_CURRENT_TRAPS ($sig);
   my $msg = "Found the function to forward to for signal '${sig}'.";

   if ( $#funcs == -1 ) {
      dbug_ok ($allow, $msg . '  ()');
   } else {
      dbug_ok (1, $msg . " -->  (" . join (", ", @funcs) . ')');
   }

   eval {
      trigger_int ( $sig, $sMsg, @funcs );
   };
   if ( $@ ) {
      DBUG_CATCH ();
   }

   push (@funcs, "local_signal_test");
   DBUG_TRAP_SIGNAL ($sig, $act, @funcs);

   DBUG_VOID_RETURN ();
}

# -----------------------------------------------
sub trigger_int
{
   DBUG_ENTER_FUNC (@_);
   my $sig   = shift;    # For INT or __DIE__.
   my $msg   = shift;
   my @funcs = @_;       # Not used, just for logging in fish.

   # Now always call the signal indirectly ...
   simulate_windows_signal ( $sig, $msg );

   DBUG_VOID_RETURN ();
}

# -----------------------------------------------
sub here_is_one_long_function_name
{
   DBUG_ENTER_FUNC (@_);
   DBUG_VOID_RETURN ();
}

# -----------------------------------------------
# Just has the test plan count that the signal call has been made!
my $total = 0;

sub local_signal_test
{
   DBUG_ENTER_FUNC (@_);
   dbug_ok (1, "In main::local_signal_test (" . ++$total . ")");
   DBUG_VOID_RETURN ();
}

