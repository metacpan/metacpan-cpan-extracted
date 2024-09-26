#!/user/bin/perl

use strict;
use warnings;

use Test::More;
use File::Spec;
use Sub::Identify 'sub_fullname';

# Program:  30-signal_traps.t
# ---------------------------------------------------------------------
# This test script validates ENTER/EXIT balancing of function calls.
# It also tests the logic for trapping evals & signals!
# ---------------------------------------------------------------------
# Does similar tests as: t/33-signal_try_tiny.t

my $windows;
my $start_level;

sub my_warn
{
   ok3 (0, "There was an expected warning!  Check fish.");
}

my $ignore_count = 0;
sub my_warn_ignore
{
   chomp (my $msg = shift);

   ++$ignore_count;
   DBUG_PRINT ("my_warn_ignore", "[%s]", $msg);
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

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
      exit (0);
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

   ok2 ( $trap, "Trapped WARNINGS with error checking!" );

   $start_level = test_fish_level ();
   is2 ($start_level, $lvl, "In the BEGIN block ...");

   ok3 ( dbug_active_ok_test () );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);

   my $end_level = test_fish_level ();
   # is2 ($end_level, $start_level, "In the END block ...");

   # So we don't have to count the test cases ...
   # Per standards it's a no-no to put into an end block,
   # but in this case it's a go!
   # done_testing ();

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
   ok2 (DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn_ignore ),
        "Now ignoring WARNINGS!");

   warn ("Adding line number to the fish message.\n");
   warn ("No line number added to the fish message.  Since already there.");

   # Re-enable treating any warnings as an error ...
   ok2 (DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn ),
        "Now treating WARNINGS as failed test cases again!");

   is2 ($ignore_count, 2, "Ignored only 2 explicit warnings with line numbers.");

   # An undocumented trace level to also show DBUG internal fish usage.
   # Can't use DBUG_FILER_LEVEL_INTERNAL in BEGIN()!
   DBUG_PRINT ("-----", "-"x40);
   DBUG_FILTER ( DBUG_FILTER_LEVEL_INTERNAL );
   DBUG_PRINT ("-----", "-"x40);

   is2 (test_fish_level(), $start_level, "In the MAIN program ...");

   # Signal INT is ^C.
   ok2 (DBUG_TRAP_SIGNAL ("INT", DBUG_SIG_ACTION_DIE, "custom_trap_sig"),
        "Signal INT has been trapped to die on trap!");

   # Defines an anonymous function ...
   my $f = sub { ok3 (0, "Hello my friend!  I should never be called!"); };

   # Traps all calls to die ... (Including when hit ^C!)
   # Demonstrates all 4 ways to specify a fuction to call!
   ok2 (DBUG_TRAP_SIGNAL ("__DIE__", DBUG_SIG_ACTION_DIE, "main::custom_trap_die", "custom_die_and_die_again", \&custom_die_never_called, $f),
        "Signal DIE has been trapped with custom functions!");

   my ($action, @flst) = DBUG_FIND_CURRENT_TRAPS ("__DIE__");
   my $num = @flst;
   ok3 ($num == 4, "Trap found the correct number of functions returned! ($num vs 4): " . join (", ", @flst));

   my $x;
   ok2 ( chk_func_names ($flst[0], 'main::custom_trap_die',          "Correct 1st trap func.") );
   ok2 ( chk_func_names ($flst[1], 'main::custom_die_and_die_again', "Correct 2nd trap func.") );
   ok2 ( chk_func_names ($flst[2], 'main::custom_die_never_called',  "Correct 3rd trap func.") );
   ok2 ( chk_func_names ($flst[3], 'main::__ANON__',                 "Correct 4th trap func.") );

   DBUG_PRINT ("INFO", "Hello %s%s\nGood Bye!\n\n", "World", "!");

   DBUG_PRINT ("====", "%s", "="x80);
   ok3 (1, "Starting DBUG_ENTER_FUNC()/DBUG_CATCH() balancing for signal tests ...");

   ok3 (1, "----------------------------------------------");
   my $level = 1;
   foreach my $i (0..1) {
      trigger_int ("INT");
      is2 (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("====", "%s", "!"x80);

      trigger_int ("INT", 1);
      is2 (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("----", "%s", "^"x80);

      trigger_die ();
      is2 (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("----", "%s", "?"x80);

      trigger_die (1);
      is2 (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("~~~~", "%s", "~"x80);

      my ( $act, @funcs ) = DBUG_FIND_CURRENT_TRAPS ("INT");
      my $cnt = $#funcs + 1;
      is2 ( $cnt, 1, "Trap found correct number of functions returned!");
      push (@funcs, "extra_signal");
      ok2 (DBUG_TRAP_SIGNAL ("INT", $act, @funcs),
           "Added extra forward function to Signal INT Trap!");

      ( $act, @funcs ) = DBUG_FIND_CURRENT_TRAPS ("INT");
      $cnt = $#funcs + 1;
      is2 ( $cnt, 2, "Trap found correct number of functions returned!");
      ok3 ( chk_func_names ($funcs[0], 'main::custom_trap_sig', "Correct 1st trap func.") );
      ok3 ( chk_func_names ($funcs[1], 'main::extra_signal',    "Correct 2nd trap func.") );

      DBUG_PRINT ("INFO", "Adding an extra trap signal!  (%s)", join (", ", @funcs));

      DBUG_PRINT ("----", "%s", "-"x80);

      trigger_int ("INT", 0);
      is2 (test_fish_level(), $start_level, "Level ${level} Test ...");
      ++$level;

      DBUG_PRINT ("~~~~", "%s", "~"x80);

      # Reset back to default action ...
      ok2 (DBUG_TRAP_SIGNAL ("INT", DBUG_SIG_ACTION_DIE, "custom_trap_sig"),
           "Reset Signal INT back to defaultl trap!");

      ok3 (1, "----------------------------------------------");
      ok3 (1, "Starting DBUG_PRINT_BLOCK() eval tests ...")  if ( $global_flag );

      # Now use DBUG_ENTER_BLOCK() instead ...
      $global_flag = 0;
   }

   # When being removed, it ignores the forward to funcions ...
   ok2 (DBUG_TRAP_SIGNAL ("INT", DBUG_SIG_ACTION_REMOVE, "custom_trap_sig"),
        "Removed the trap for Signal INT!");

   ($action, @flst) = DBUG_FIND_CURRENT_TRAPS ("INT");
   ok3 ( $#flst == -1 && ! $action,
         "The INT Signal is no longer being trapped! " . join ("\n", @flst) );


    $global_flag = 1;

   # Don't put any more tests after this warning test ...
   ok2 (DBUG_TRAP_SIGNAL ("WARN", DBUG_SIG_ACTION_DIE, "custom_trap_sig"),
        "Now causing WARN to die!");

   eval {
      warn ("Will you let us die for warning you?\n");
   };
   if ($@) {
      ok2 (1, "Trapped warning!  We rescued you from dying!");
   } else {
      ok2 (0, "Trapped warning!  We rescued you from dying!");
   }

   my ($managed, $eval_catch, $triggered_by, $rethrown, $die_action) = DBUG_DIE_CONTEXT ();
   my $flg = (! $eval_catch) && (! $managed);
   ok3 ($flg, "Called outside a trapped Signal calling die [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");

   eval {
      DBUG_ENTER_FUNC("XXXXXXXXXXXXXXXXXXXXXXX");
      ($managed, $eval_catch, $triggered_by, $rethrown, $die_action) = DBUG_DIE_CONTEXT ();
      $flg = $eval_catch && (! $managed);
      ok3 ($flg, "Calling from eval block & outside a trapped Signal [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");
      die ("For the final time!\n");
      DBUG_VOID_RETURN ();
   };
   if ($@) {
      DBUG_CATCH();
   }

   ok3 ( 1, "Fish File: " . DBUG_FILE_NAME () );

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
   ok3 ($managed, "Caught the trapped die request! ($msg) [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");
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
   ok3 ($managed, "Caught the trapped die request! ($msg) [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");

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
   ok3 ($managed, "Caught the trapped die request! ($msg) [Context: $managed, $eval_catch, $triggered_by, $rethrown, $die_action]");

   ok3 (0, "Expected to make this call!");
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
   ok3 (1, "Caught the trapped signal! ($_[0])");
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
   ok3 (1, "Caught the extra trapped signal! ($opt)");
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

   eval {
      die ("Here goes life number 1!\n");
   };
   if ( $@ ) {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("EVAL", "The Die was trapped in *** %s ***!", $func);
      ok3 (($func eq $name), "Popped the Fish stack correctly in eval!  ($func vs $name)");
   }
   my $lvl = test_fish_level ();
   is2 ($lvl, $orig_lvl, "Stack balanced after 1st DIE test.");

   DBUG_PRINT ("--2nd--", "---------------------------------------------------------");

   eval {
      ( $global_flag ? DBUG_ENTER_FUNC () : DBUG_ENTER_BLOCK ("eval") );
      die ("Here goes life number 2!\n");
      DBUG_VOID_RETURN ();
   };
   if ( $@ ) {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("EVAL", "The Die was trapped in *** %s ***!", $func);
      is2 ($name, $func, "Popped the Fish stack correctly in eval!");
   }
   $lvl = test_fish_level ();
   is2 ($lvl, $orig_lvl, "Stack balanced after 2nd DIE test.");

   DBUG_PRINT ("--3rd--", "---------------------------------------------------------");

   eval {
      ( $global_flag ? DBUG_ENTER_FUNC () : DBUG_ENTER_BLOCK ("eval") );
      eval {
         ( $global_flag ? DBUG_ENTER_FUNC () : DBUG_ENTER_BLOCK ("eval") );
         die ("Here goes life number 3!  (2 evals deep!)\n");
         DBUG_VOID_RETURN ();
      };
      if ( $@ ) {
         die ( $@ );
      }
      DBUG_VOID_RETURN ();
   };
   if ( $@ ) {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("EVAL", "The Die was trapped in *** %s ***!", $func);
      is2 ($name, $func, "Popped the Fish stack correctly in eval!");
   }
   $lvl = test_fish_level ();
   is2 ($lvl, $orig_lvl, "Stack balanced after 3rd DIE test.");

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

   eval {
      # trigger_signal ($sig, $mode);
      trigger_int_level_1 ($sig, $mode);
   };

   if ( $@ ) {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("EVAL", "The Die was trapped in *** %s ***!", $func);
      is2 ($name, $func, "Popped the Fish stack correctly in eval!");
   }

   my $lvl = test_fish_level ();
   is2 ($lvl, $orig_lvl, "Stack balanced after INT tests.");

   DBUG_PRINT ("--2nd--", "---------------------------------------------------------");

   eval {
      ( $global_flag ? DBUG_ENTER_FUNC () : DBUG_ENTER_BLOCK ("eval") );
      trigger_int_level_21 ($sig, $mode);
      DBUG_VOID_RETURN();
   };
   if ( $@ ) {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("EVAL", "The Die was trapped in *** %s ***!", $func);
      is2 ($name, $func, "Popped the Fish stack correctly in eval!");
   }

   $lvl = test_fish_level ();
   is2 ($lvl, $orig_lvl, "Stack balanced after more INT tests.");

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
   eval {
      trigger_int_level_24 (@_);
   };
   if ( $@ ) {
      DBUG_CATCH ();
      my $name = test_func_name_no_warn ( $func );
      DBUG_PRINT ("EVAL", "The Die was trapped in *** %s ***!", $func);
      is2 ($name, $func, "Popped the Fish stack correctly in eval!");
      DBUG_PRINT ("DUP", "**** Calling die() with the same trapped message!  Context should say Rethrown TRUE! ****");
      die ( $@ );    # Rethrow the error!
   }
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

