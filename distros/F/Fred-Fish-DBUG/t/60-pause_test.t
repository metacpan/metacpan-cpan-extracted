#!/user/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  60-pause_test.t
# ---------------------------------------------------------------------
# This test script validates ENTER/EXIT balancing of function calls.
# It also tests the logic for trapping evals & signals!
# ---------------------------------------------------------------------

my $start_level;

sub my_warn
{
   dbug_ok (0, "There was an expected warning!  Check fish.");
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
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

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   dbug_is ($start_level, $lvl, "In the BEGIN block ...");

   dbug_ok ( dbug_active_ok_test () );

   dbug_ok ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   my $lvl = test_fish_level ();
   dbug_is ($lvl, $start_level, "In the END block ...");

   # So we don't have to count the test cases ...
   # Per standards it's a No-No to put into an end block,
   # but in this case it's a go!  I don't care if tests
   # are skipped on failures for this program!
   done_testing ();

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# The start of the MAIN program!
# ----------------------------------------------------------------

{
   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");

   pause_1 ();
   pause_2 ();
   eval_pause ();
   pause_block ();
   pause_good_warn ();

   my $lvl = test_fish_level ();
   dbug_is ($lvl, $start_level, "MAIN Level Check");

   DBUG_LEAVE (0);
}

sub pause_1
{
   DBUG_ENTER_FUNC (@_);
   DBUG_PAUSE ();
   dbug_ok (1, "First pause test");
   DBUG_VOID_RETURN ();
}

sub pause_2
{
   DBUG_ENTER_FUNC (@_);
   dbug_ok (1, "Pause Test 1 (of 3)");
   DBUG_PAUSE ();
   dbug_ok (1, "Pause Test 2 (of 3)");
   DBUG_PAUSE ();
   dbug_ok (1, "Pause Test 3 (of 3)");
   DBUG_VOID_RETURN ();
}

sub eval_pause
{
   DBUG_ENTER_FUNC (@_);
   eval {
      dbug_ok (1, "Eval Test # 1!");
      DBUG_PAUSE();
      dbug_ok (1, "Eval Test # 2!");
      DBUG_PAUSE();
      dbug_ok (1, "Eval Test # 3!");
   };
   DBUG_VOID_RETURN ();
}

sub pause_block
{
   DBUG_ENTER_FUNC (@_);
   dbug_ok (1, "Pause Block Test");

   DBUG_ENTER_BLOCK ("unknown");
   DBUG_PAUSE ();
   dbug_ok (1, "Pause Block Test 2!");
   DBUG_VOID_RETURN ();
   dbug_ok (1, "Pause Block Test Ended!");

   DBUG_VOID_RETURN ();
}

sub my_warn_ok
{
   chomp (my $msg = shift);
   dbug_ok (1, "__WARN__ : " . $msg);
}

# Shows even when fish is paused, the warning still
# gets written to fish ...
sub pause_good_warn
{
   DBUG_ENTER_FUNC (@_);
   DBUG_PAUSE ();
   dbug_ok (1, "Pause Good Warn test 1!");
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn_ok );
   warn ("This warning was generated while Pause is on!");
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );
   dbug_ok (2, "Pause Good Warn test 2!");
   DBUG_VOID_RETURN ();
}

