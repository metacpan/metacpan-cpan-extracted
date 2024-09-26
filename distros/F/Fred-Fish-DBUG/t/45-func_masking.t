#!/user/bin/perl

# Program:  45-func_masking.t
# Tests out the masking of function call arguments!

# All test functions have a dummy 1st argument called ${mask}
# Which is stripped from the argument stack before
# the DBUG_ENTER_...() functions are called.
# So this argument doesn't show up in fish!
# It's present even if it's not technically needed!
# It's used to predict how many arguments should be masked!

# This allows us to dynamically mask arguments
# that doesn't show up in fish.  That argument predicts how
# many entries should be masked so can automate test results!


use strict;
use warnings;

# Count tests since END does some!
use Test::More tests => 28;
use File::Spec;

my $start_level;

sub my_warn
{
   ok3 (0, "There was an expected warning!  Check fish.");
}

# Used to determine how many arguments were actually
# masked via the the previous DBUG_ENTER_..() function call.
sub mask_assist
{
   my $cheat = shift;

   # The cheat is ignored if not used for Fred::Fish::DBUG::OFF ...
   # my $cnt = ${fish_module}->dbug_mask_argument_counts ($cheat);  # Wrong way ...
   # my $cnt = ${fish_module}->can ('dbug_mask_argument_counts')->($cheat);  # Right way ...

   my $cnt = test_mask_args ($cheat);

   return ( $cnt );
}


# Any DBUG_MASK_NEXT_FUNC_CALL() masking is done by caller.
# Done this way to allow variable masking.
sub func2
{
   my $mask = shift;    # Remove the expected mask count ...
   DBUG_ENTER_FUNC (@_);
   my $cnt = mask_assist ( $mask );
   ok3 ( $cnt == $mask, "Function func2(${cnt}) had ${mask} paramerter(s) masked!");
   DBUG_VOID_RETURN ();
}


BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   push (@INC, File::Spec->catdir (".", "t", "off"));

   # Helper module makes sure DIE & WARN traps are set ...
   unless (use_ok ("helper1234")) {
      done_testing ();
      BAIL_OUT ( "Can't load helper1234" );   # Test # 1
      exit (0);
   }

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {     # Test # 2
      bail ( "Can't load $fish_module via Fred::Fish::DBUG qw / " .
             join (" ", @opts) . " /" );
   }

   ok (1, "Used options qw / " . join (" ", @opts) . " /");

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
      exit (0);
  }
}

BEGIN {
   # So can detect if the module generates any unexpected warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => ${off} );

   my $lvl = ( get_fish_state () == -1 ) ? -1 : 1;

   DBUG_ENTER_FUNC (@ARGV);

   $start_level = test_fish_level ();
   is2 ($start_level, $lvl, "In the BEGIN block ...");   # Test # 2
   DBUG_PRINT ("PURPOSE", "\nJust verifying that the masking of function arguments are good!\n.");

   DBUG_MASK_NEXT_FUNC_CALL (-1);
   func2(4, "B01", "B02", "B03", "B04");

   $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "BEGIN Level Check Worked!");

   ok3 ( dbug_active_ok_test () );

   ok3 ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   ok3 (1, "In the END block ...");     # Test # 12
   DBUG_MASK_NEXT_FUNC_CALL (-1);
   DBUG_MASK_NEXT_FUNC_CALL (1);
   func2(1, "E01", "E02", "E03");
   my $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "END Level Check Worked!");

   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   ok3 (1, "In the MAIN program ...");  # Test # 4 ...

   func1(0, 1, 2, 3);
   block_test(0, "Test-1", "Test-2", "Test-3");
   eval_test(0);
   eval_block_test(0);

   DBUG_PRINT ("INFO", "This is a test line!");
   level_test();

   my $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "MAIN Level Check Worked!");

   DBUG_LEAVE (0);
}

# -----------------------------------------------
sub level_test
{
   DBUG_ENTER_FUNC (@_);
   DBUG_PRINT ("INFO", "Another test line!");
   DBUG_VOID_RETURN ();
}

sub func1
{
   my $mask = shift;   # Remove the expected mask count ...
   DBUG_ENTER_FUNC (@_);

   my $cnt = mask_assist ($mask);
   ok3 ( $cnt == $mask, "Function func1() had ${mask} paramerter(s) masked!");

   DBUG_MASK_NEXT_FUNC_CALL ("hint");
   DBUG_MASK_NEXT_FUNC_CALL (0, 2, 4, 6);
   func2(2, "F1", "F2", "F3", "Double called MASK func.");
   func2(0, "F1", "F2", "F3");
   func3(2, "One", "Fine", "Day", Password => "I should be masked!", Junker => "Always!", PassWord => "Mask me!");
   func3(1, "Fish", "Shark", "Whales", Passwords => "I'm not masked!", Junker => "Never!", PassWord => "Mask me!");
   DBUG_VOID_RETURN ();
}

sub func3
{
   my $mask = shift;   # Remove the expected mask count ...

   DBUG_MASK_NEXT_FUNC_CALL ("password");
   DBUG_ENTER_FUNC (@_);

   my $cnt = mask_assist ($mask);
   ok3 ( $cnt == $mask, "Function func3($cnt) had ${mask} paramerter(s) masked!");

   if (1==1) {
      DBUG_ENTER_BLOCK ("nameless");
      $cnt = mask_assist (0);
      ok3 ($cnt == 0, "Nameless block test!");
      DBUG_VOID_RETURN ();
   }

   DBUG_VOID_RETURN ();
}

sub block_test
{
   my $mask = shift;   # Remove the expected mask count ...
   DBUG_ENTER_BLOCK ("block_test");
   my $cnt = mask_assist (0);
   ok3 ($cnt == 0, "Block test without FUNC!");
   DBUG_VOID_RETURN ();
}

sub eval_test
{
   my $mask = shift;   # Remove the expected mask count ...
   DBUG_ENTER_FUNC (@_);

   my $cnt = mask_assist ($mask);
   ok3 ($cnt == $mask, "Function eval_test() masked $mask parameters.");

   eval {
      DBUG_MASK_NEXT_FUNC_CALL (-1);
      DBUG_ENTER_FUNC ();
      $cnt = mask_assist (0);
      DBUG_MASK_NEXT_FUNC_CALL (2, 33);
      func2(1, "EVAL-1", "EVAL-2", "EVAL-3");
      ok3 ($cnt == 0, "Eval test!");
      DBUG_VOID_RETURN ();
   };
   DBUG_VOID_RETURN ();
}

sub eval_block_test
{
   my $mask = shift;   # Remove the expected mask count ...
   DBUG_ENTER_BLOCK ("eval_block_test");

   my $cnt = mask_assist (0);
   ok3 ($cnt == 0, "Function eval_block_test() masked 0 parameters.");

   eval {
      DBUG_MASK_NEXT_FUNC_CALL (-1);
      DBUG_ENTER_BLOCK ("**EVAL**");
      $cnt = mask_assist (0);
      DBUG_MASK_NEXT_FUNC_CALL (0, 22);
      func2(1, "EVAL-1", "EVAL-2", "EVAL-3");
      ok3 ($cnt == 0, "Eval block test!");
      DBUG_VOID_RETURN ();
   };
   DBUG_VOID_RETURN ();
}

