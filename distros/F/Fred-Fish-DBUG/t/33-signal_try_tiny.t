#!/user/bin/perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use Sub::Identify 'sub_fullname';

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  33-signal_try_tiny.t
# ---------------------------------------------------------------------
# This test script validates ENTER/EXIT balancing of function calls.
# It also tests the logic for trapping try/catch blocks & signals!
# ---------------------------------------------------------------------
# Does similar tests as: t/30-signal_traps.t

# ---------------------------------------------------------------------
# What are try/catch blocks?
# Try::Tiny::try is a special function that takes as it's arguments the
# code block following it + the catch function & it's code block.
# When you call try in your code, it wraps the code block up inside
# an eval block & then calls the code block as an anonymous function.
# And if the eval traps die, it then calls the Try::Timy::catch for you.
# ---------------------------------------------------------------------
# There are a couple fo gotchas compared to using "eval" directly.
#  1) Special variable @_ is always the empty array in the try block.
#  2) Special variable $@ doesn't have the error message in the catch
#     block.  It uses $_ instead!
# ---------------------------------------------------------------------

my $windows;
my $start_level;

sub my_warn
{
   dbug_ok (0, "There was an expected warning!  Check fish.");
}

my $ignore_count = 0;
sub my_warn_ignore
{
   chomp (my $msg = shift);

   ++$ignore_count;
   DBUG_PRINT ("-----", "[%s]", $msg);
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
   my $trap = DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   my $sts = get_fish_state ();   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( $sts == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off, multi => 0, who_called => 0 );

   my $os = $^O;
   $windows = ($os eq "MSWin32");

   my $lvl = ( $sts == -1 ) ? -1 : 1;

   DBUG_ENTER_FUNC ();

   dbug_ok ( $trap, "Trapped WARNINGS with error checking!" );

   $start_level = test_fish_level ();
   dbug_is ($start_level, $lvl, "In the BEGIN block ...");

   dbug_ok ( dbug_active_ok_test () );

   DBUG_VOID_RETURN ();
}

# Must do after Fred-Fish-DBUG logs are running ...
# Do not use "eval" anywhere else in this code!
# NOTE: Try::Tiny thorws/traps die during initializaton & I don't
#       want to log those calls to die in fish!  This common issue is
#       another reason for not starting fish logging in BEGIN blocks!
BEGIN {
   DBUG_ENTER_FUNC (@_);

   # Ignore the fancy overrides for the DIE signal ...
   local $SIG{__DIE__} = "DEFAULT";

   eval {
      require Try::Tiny;
      Try::Tiny->import ();
   };
   if ( $@ ) {
      dbug_ok (1, "Skipping Signal Tests.  Try::Tiny is not installed!");
      done_testing ();
      DBUG_LEAVE (0);
   }

   dbug_ok (1, "ModuleTry::Tiny is installed!");

   DBUG_VOID_RETURN ();
}

# Only report error in the end block to avoid Test::More issues.
END {
   DBUG_ENTER_FUNC (@_);

   my $end_level = test_fish_level ();
   if ( $start_level != $end_level ) {
      dbug_ok (0, "In the END block ...");
   }

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# The start of the MAIN program!
# ----------------------------------------------------------------

# If 1, use DBUG_ENTER_FUNC ()
# If 0, use DBUG_ENTER_BLOCK ()
# in DBUG_CATCH() tests ...
# Both should be equivalent, and so this will prove it!
my $global_flag = 1;


{
   DBUG_ENTER_FUNC (@ARGV);

   # Don't treat these explicit warnings as errors ...
   dbug_ok (DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn_ignore ),
            "Now ignoring WARNINGS!");

   warn ("Adding line number to the fish message.\n");
   warn ("No line number added to the fish message.  Since already there.");

   # Re-enable treating any warnings as an error ...
   dbug_ok (DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn ),
            "Now treating WARNINGS as failed test cases again!");

   dbug_is ($ignore_count, 2, "Ignored only 2 explicit warnings with line numbers.");

   # An undocumented trace level to also show DBUG internal fish usage.
   # Can't use DBUG_FILER_LEVEL_INTERNAL in BEGIN()!
   DBUG_PRINT ("-----", "-"x40);
   DBUG_FILTER ( DBUG_FILTER_LEVEL_INTERNAL );
   DBUG_PRINT ("-----", "-"x40);

   dbug_is (test_fish_level(), $start_level, "In the MAIN program ...");

   # Signal INT is ^C.
   dbug_ok (DBUG_TRAP_SIGNAL ("INT", DBUG_SIG_ACTION_DIE, "custom_trap_sig"),
            "Signal INT has been trapped to die on trap!");

   # Defines an anonymous function ...
   my $f = sub { dbug_ok (0, "Hello my friend!  I should never be called!"); };

   # Traps all calls to die ... (Including when hit ^C!)
   # Demonstrates all 4 ways to specify a fuction to call!
   dbug_ok (DBUG_TRAP_SIGNAL ("__DIE__", DBUG_SIG_ACTION_DIE, "main::custom_trap_die", "custom_die_and_die_again", \&custom_die_never_called, $f),
            "Signal DIE has been trapped with custom functions!");

   my ($action, @flst) = DBUG_FIND_CURRENT_TRAPS ("__DIE__");
   my $num = @flst;
   dbug_is ($num, 4, "Trap found the correct number of functions returned! ($num vs 4): " . join (", ", @flst));

   my $x;
   dbug_ok ( chk_func_names ($flst[0], 'main::custom_trap_die',          "Correct 1st trap func.") );
   dbug_ok ( chk_func_names ($flst[1], 'main::custom_die_and_die_again', "Correct 2nd trap func.") );
   dbug_ok ( chk_func_names ($flst[2], 'main::custom_die_never_called',  "Correct 3rd trap func.") );
   dbug_ok ( chk_func_names ($flst[3], 'main::__ANON__',                 "Correct 4th trap func.") );

   DBUG_PRINT ("INFO", "Hello %s%s\nGood Bye!\n\n", "World", "!");

   DBUG_PRINT ("====", "%s", "="x80);
   dbug_ok (1, "Starting DBUG_ENTER_FUNC()/DBUG_CATCH() balancing for signal tests ...");

   dbug_ok (1, "----------------------------------------------");
   my $level = 1;
   foreach my $i (0..1) {
      trigger_int ("INT");
      dbug_is (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("====", "%s", "!"x80);

      trigger_int ("INT", 1);
      dbug_is (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("----", "%s", "^"x80);

      trigger_die ();
      dbug_is (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("----", "%s", "?"x80);

      trigger_die (1);
      dbug_is (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("~~~~", "%s", "~"x80);

      my ( $act, @funcs ) = DBUG_FIND_CURRENT_TRAPS ("INT");
      my $cnt = $#funcs + 1;
      dbug_is ($cnt, 1, "Trap found correct number of functions returned!");
      push (@funcs, "extra_signal");
      dbug_ok (DBUG_TRAP_SIGNAL ("INT", $act, @funcs),
               "Added extra forward function to Signal INT Trap!");

      ( $act, @funcs ) = DBUG_FIND_CURRENT_TRAPS ("INT");
      $cnt = $#funcs + 1;
      dbug_is ($cnt, 2, "Trap found correct number of functions returned!");
      dbug_ok ( chk_func_names ($funcs[0], 'main::custom_trap_sig', "Correct 1st trap func.") );
      dbug_ok ( chk_func_names ($funcs[1], 'main::extra_signal',    "Correct 2nd trap func.") );

      DBUG_PRINT ("INFO", "Adding an extra trap signal!  (%s)", join (", ", @funcs));

      DBUG_PRINT ("----", "%s", "-"x80);

      trigger_int ("INT", 0);
      dbug_is (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("~~~~", "%s", "~"x80);

      # Reset back to default action ...
      dbug_ok (DBUG_TRAP_SIGNAL ("INT", DBUG_SIG_ACTION_DIE, "custom_trap_sig"),
               "Reset Signal INT back to defaultl trap!");

      dbug_ok (1, "----------------------------------------------");
      dbug_ok (1, "Starting DBUG_PRINT_BLOCK() eval tests ...")  if ( $global_flag );

      # Now use DBUG_ENTER_BLOCK() instead ...
      $global_flag = 0;
   }

   # When being removed, it ignores the forward to funcions ...
   dbug_ok (DBUG_TRAP_SIGNAL ("INT", DBUG_SIG_ACTION_REMOVE, "custom_trap_sig"),
            "Removed the trap for Signal INT!");

   ($action, @flst) = DBUG_FIND_CURRENT_TRAPS ("INT");
   dbug_ok ( $#flst == -1 && ! $action,
           "The INT Signal is no longer being trapped! " . join ("\n", @flst) );


   $global_flag = 1;

   # Don't put any more tests after this warning test ...
   dbug_ok (DBUG_TRAP_SIGNAL ("WARN", DBUG_SIG_ACTION_DIE, "custom_trap_sig"),
            "Now causing WARN to die!");

   try {
      warn ("Will you let us die for warning you?\n");
      dbug_ok (0, "Trapped warning!  We rescued you from dying!");
   } catch {
      dbug_ok (1, "Trapped warning!  We rescued you from dying!");
   };

   my ($managed, $eval_catch, $triggered_by, $rethrown, $die_action) = DBUG_DIE_CONTEXT ();
   my $flg = (! $eval_catch) && (! $managed);
   dbug_ok ($flg, "Called outside a trapped Signal calling die [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");

   try {
      DBUG_ENTER_FUNC("XXXXXXXXXXXXXXXXXXXXXXX");
      ($managed, $eval_catch, $triggered_by, $rethrown, $die_action) = DBUG_DIE_CONTEXT ();
      $flg = $eval_catch && (! $managed);
      dbug_ok ($flg, "Calling from try block & outside a trapped Signal [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");
      DBUG_PRINT ("INFO", "Calling die!");
      die ("For the final time!\n");
      DBUG_VOID_RETURN ();
   } catch {
      DBUG_CATCH ();
      DBUG_ENTER_FUNC("YYYYYYYYYYYYYYYYYYYYYYY");
      DBUG_PRINT ("INFO", "Back from the dead!");
      ($managed, $eval_catch, $triggered_by, $rethrown, $die_action) = DBUG_DIE_CONTEXT ();
      $flg = (! $eval_catch) && (! $managed);
      dbug_ok ($flg, "Calling from catch block & outside a trapped Signal [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");
      DBUG_VOID_RETURN ();
   } finally {
      DBUG_ENTER_FUNC("ZZZZZZZZZZZZZZZZZZZZZZZ");
      DBUG_PRINT ("INFO", "Being burried again!");
      $flg = (! $eval_catch) && (! $managed);
      dbug_ok ($flg, "Calling from finally block & outside a trapped Signal [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");
      DBUG_VOID_RETURN ();
   };

   dbug_ok ( 1, "Fish File: " . DBUG_FILE_NAME () );

   # Tell Test::More we're done with the testing!
   done_testing ();

   DBUG_LEAVE (0);
}

# ----------------------------------------------------------------
# For validating the returned code reference
# ----------------------------------------------------------------
sub chk_func_names
{
   DBUG_ENTER_FUNC (@_);
   my $code_ref  = shift;
   my $func_name = shift || "";
   my $ok_msg    = shift;

   my $res = 0;   # Assume failure
   my $real_name = $code_ref;

   if ( ref ($code_ref) eq "CODE" ) {
      $real_name = sub_fullname ($code_ref);

      if ( $real_name eq $func_name ) {
         $res = 1;     # Yes it's the expected value!
      }
   }

   $ok_msg .= "  " . $real_name;

   DBUG_RETURN ($res, $ok_msg);
}


# ----------------------------------------------------------------
# These trap functions are called indirectly ...
# ----------------------------------------------------------------
sub custom_trap_die
{
   if ( $global_flag ) {
      DBUG_ENTER_FUNC (@_);
   } else {
      DBUG_ENTER_BLOCK ("custom_trap_die", @_);
   }
   my $msg = shift;
   chomp($msg);
   DBUG_PRINT ("TRAP-DIE", "%s", "Oh why, oh why did I have to die?");
   my ($managed, $eval_catch, $triggered_by, $rethrown, $die_action) = DBUG_DIE_CONTEXT ();
   dbug_ok ($managed, "Caught the trapped die request! ($msg) [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");
   DBUG_VOID_RETURN ();
}

sub custom_die_and_die_again
{
   if ( $global_flag ) {
      DBUG_ENTER_FUNC (@_);
   } else {
      DBUG_ENTER_BLOCK ("custom_trap_die", @_);
   }
   my $msg = shift;
   chomp($msg);

   my ($managed, $eval_catch, $triggered_by, $rethrown, $die_action) = DBUG_DIE_CONTEXT ();
   dbug_ok ($managed, "Caught the trapped die request! ($msg) [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");

   die ( $msg . "\n" );
   DBUG_VOID_RETURN ();
}

# Since called after custom_die_and_die_again(), the trap code shouldn't call me!
# Proving this by having a test fail!
sub custom_die_never_called
{
   if ( $global_flag ) {
      DBUG_ENTER_FUNC (@_);
   } else {
      DBUG_ENTER_BLOCK ("custom_trap_die", @_);
   }
   my $msg = shift;
   chomp($msg);

   my ($managed, $eval_catch, $triggered_by, $rethrown, $die_action) = DBUG_DIE_CONTEXT ();
   dbug_ok ($managed, "Caught the trapped die request! ($msg) [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");

   dbug_ok (0, "Expected to make this call!");
   DBUG_VOID_RETURN ();
}

sub custom_trap_sig
{
   if ( $global_flag ) {
      DBUG_ENTER_FUNC (@_);
   } else {
      DBUG_ENTER_BLOCK ("custom_trap_sig", @_);
   }
   DBUG_PRINT ("TRAP-$_[0]", "Trapped Signal: [%s]", $_[0]);
   dbug_ok (1, "Caught the trapped signal! ($_[0])");
   DBUG_VOID_RETURN ();
}

sub extra_signal
{
   if ( $global_flag ) {
      DBUG_ENTER_FUNC (@_);
   } else {
      DBUG_ENTER_BLOCK ("extra_signal", @_);
   }
   my $opt = shift;
   chomp($opt);
   dbug_ok (1, "Caught the extra trapped signal! ($opt)");
   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# Trapping the DIE request ...
# ----------------------------------------------------------------
sub trigger_die
{
   my $func;
   if ( $global_flag ) {
      $func = DBUG_ENTER_FUNC (@_);
   } else {
      $func = DBUG_ENTER_BLOCK ("trigger_die", @_);
   }
   my $pause_flag = shift || 0;

   DBUG_PRINT ("CATS", "Cat's have 9 lives.\nLets see how often we can make them die!");

   my $orig_lvl = test_fish_level ();
   DBUG_PAUSE ()  if ($pause_flag);

   try {
      die ("Here goes life number 1!\n");
   } catch {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("TRY/CATCH", "The Die was trapped in *** %s ***!", $func);
      dbug_is ($name, $func, "Popped the Fish stack correctly in try/catch!");
   };
   my $lvl = test_fish_level ();
   dbug_is ($lvl, $orig_lvl, "Stack balanced after 1st DIE test.");

   DBUG_PRINT ("--2nd--", "---------------------------------------------------------");

   try {
      ( $global_flag ? DBUG_ENTER_FUNC () : DBUG_ENTER_BLOCK ("eval") );
      die ("Here goes life number 2!\n");
      DBUG_VOID_RETURN ();
   } catch {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("TRY/CATCH", "The Die was trapped in *** %s ***!", $func);
      dbug_is ($name, $func, "Popped the Fish stack correctly in try/catch!");
   };
   $lvl = test_fish_level ();
   dbug_is ($lvl, $orig_lvl, "Stack balanced after 2nd DIE test.");

   DBUG_PRINT ("--3rd--", "---------------------------------------------------------");

   try {
      ( $global_flag ? DBUG_ENTER_FUNC () : DBUG_ENTER_BLOCK ("eval") );
      try {
         ( $global_flag ? DBUG_ENTER_FUNC () : DBUG_ENTER_BLOCK ("eval") );
         die ("Here goes life number 3!  (2 evals deep!)\n");
         DBUG_VOID_RETURN ();
      } catch {
         local $@ = $_;   # A try/catch work arround.
         die ( $@ );
      };
      DBUG_VOID_RETURN ();
   } catch {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("TRY/CATCH", "The Die was trapped in *** %s ***!", $func);
      dbug_is ($name, $func, "Popped the Fish stack correctly in try/catch!");
   };

   $lvl = test_fish_level ();
   dbug_is ($lvl, $orig_lvl, "Stack balanced after 3rd DIE test.");

   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# Trapping the INT (^C) signal ...
# ----------------------------------------------------------------
sub trigger_int
{
   my $func;
   if ( $global_flag ) {
      $func = DBUG_ENTER_FUNC (@_);
   } else {
      $func = DBUG_ENTER_BLOCK ("trigger_int", @_);
   }
   my $sig = shift;     # "INT, ...", not the numeric values ...
   my $pause_flag = shift || 0;

   my $mode = 0;    # 0 or 1 ... (did we cheat?)

   my $orig_lvl = test_fish_level ();

   DBUG_PAUSE ()  if ($pause_flag);

   try {
      # trigger_signal ($sig, $mode);
      trigger_int_level_1 ($sig, $mode);
   } catch {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("TRY/CATCH", "The Die was trapped in *** %s ***!", $func);
      dbug_is ($name, $func, "Popped the Fish stack correctly in try/catch!");
   };

   my $lvl = test_fish_level ();
   dbug_is ($lvl, $orig_lvl, "Stack balanced after INT test.");

   DBUG_PRINT ("--2nd--", "---------------------------------------------------------");

   try {
      ( $global_flag ? DBUG_ENTER_FUNC () : DBUG_ENTER_BLOCK ("eval") );
      trigger_int_level_21 ($sig, $mode);
      DBUG_VOID_RETURN();
   } catch {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("TRY/CATCH", "The Die was trapped in *** %s ***!", $func);
      dbug_is ($name, $func, "Popped the Fish stack correctly in try/catch!");
   };

   $lvl = test_fish_level ();
   dbug_is ($lvl, $orig_lvl, "Stack balanced after more INT tests.");

   DBUG_VOID_RETURN ();
}


# ----------------------------------------------------------------
# No fish on purpose here ...
# ----------------------------------------------------------------
sub trigger_int_level_1 { trigger_int_level_2 (@_); }
sub trigger_int_level_2 { trigger_int_pre_work (@_); }
sub trigger_int_level_21 { trigger_int_level_22 (@_); }
sub trigger_int_level_22 { trigger_int_level_23 (@_); }
sub trigger_int_level_24 { trigger_int_pre_work (@_); }

# ----------------------------------------------------------------
sub trigger_int_level_23 {
   my $func;
   if ( $global_flag ) {
      $func = DBUG_ENTER_FUNC (@_);
   } else {
      $func = DBUG_ENTER_BLOCK ("trigger_int_level_23", @_);
   }

   # Must do this assignment to work arround "try" 'feature'
   # which clears out the contents of @_ when it was
   # used for call to trigger_int_level_24()!
   my @lst = @_;

   try {
      trigger_int_level_24 (@lst);
      # trigger_int_level_24 (@_);   # Unsuppored in a "try" block!
   } catch {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("TRY/CATCH", "The Die was trapped in *** %s ***!", $func);
      dbuug_is ($name, $func, "Popped the Fish stack correctly in try/catch!");
      DBUG_PRINT ("DUP", "**** Calling die() with the same trapped message!  Context should say Rethrown TRUE! ****");
      local $@ = $_;   # A try/catch work arround.
      die ( $@ );      # Rethrow the error!
   };
   DBUG_VOID_RETURN ();
}


# ----------------------------------------------------------------
sub trigger_int_pre_work
{
   if ( $global_flag ) {
      DBUG_ENTER_FUNC (@_);
   } else {
      DBUG_ENTER_BLOCK ("trigger_int_pre_work", @_);
   }
   trigger_signal (@_);
   DBUG_VOID_RETURN ();
}

# ----------------------------------------------------------------
# Note:  It looks like Windows can't send a signal to itself via kill!
#        So attempts to simulate it instead.

# Note 2: Never trigger DIE/WARN signals using this function!
# ----------------------------------------------------------------
sub trigger_signal
{
   if ( $global_flag ) {
      DBUG_ENTER_FUNC (@_);
   } else {
      DBUG_ENTER_BLOCK ("trigger_signal", @_);
   }
   my $sig   = shift;     # "INT, ...", not the numeric values ...
   my $cheat = shift;     # 0 or 1.

   if ( $windows || $cheat ) {
      # Will call ok(0, $msg); on failure ...
      simulate_windows_signal ( $sig );

   } else {
      # Non-windows servers ... Don't need to cheat!
      kill ( $sig, $$ );
   }

   DBUG_VOID_RETURN ();
}

