#!/user/bin/perlmy args;

# Program:  42-func_who_called_trace.t
# Tests program traces function calls with line #'s of the caller

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

my $start_level;

sub my_warn
{
   my $msg = shift;
   unless ( $msg =~ m/^Skip -/ ) {
      dbug_ok (0, "There was an expected warning!  Check fish.");
   }
}

sub func2
{
   DBUG_ENTER_FUNC (@_);
   DBUG_VOID_RETURN ();
}

# Sets up which DBUG module to use.  DBUG vs DBUG::OFF.
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

my $fish_called_by;

BEGIN {
   # So can detect if the module generates any warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off, who_called => 1 );

   $fish_called_by = get_called_by_code_ref ();
}

my $try_tiny_flag;
my $test_obj_flag;

BEGIN {
   DBUG_ENTER_FUNC ();

   # Ignore the fancy overrides for the DIE signal ...
   local $SIG{__DIE__} = "DEFAULT";

   dbug_ok (1, "Loading optional Try::Tiny module ...");
   $try_tiny_flag = 0;
   eval {
      require Try::Tiny;
      Try::Tiny->import ();
      $try_tiny_flag = 1;
   };

   DBUG_VOID_RETURN ();
}

# Must be after fish is open to see the object traced.
# Module won't load for Perl's before v5.9.5
BEGIN {
   DBUG_ENTER_FUNC ();

   # Ignore the fancy overrides for the DIE & WARN signals ...
   local $SIG{__DIE__} = "DEFAULT";
   local $SIG{__WARN__} = "IGNORE";

   dbug_ok (1, "Loading special test_object module ...");
   eval {
      require test_object;
      $test_obj_flag = 1;
   };
   if ( $@ ) {
      $test_obj_flag = 0;
   }

   DBUG_VOID_RETURN ();
}

BEGIN {
   DBUG_ENTER_FUNC ();
   dbug_ok (1, "In the noop BEGIN block ...");
   DBUG_VOID_RETURN ();
}


sub validate_line
{
   my $msg  = shift;
   my $name = shift || test_func_name() || "";
   my $expected = shift || ((caller(0))[2] - 1);

   # 0 - means its a bad parse ...
   my $line = ( $msg =~ m/ line (\d+)$/ ) ? $1 : 0;

   # "" - means its a bad parse ...
   my $func = ( $msg =~ m/^([^\s]+)\s/ ) ? $1 : "";

   dbug_is ( $line, $expected, $msg . "   ($line vs $expected)" );
   if ( $name ) {
      dbug_is ( $name, $func, "Correct function name provided. ($name vs $func)" );
   } else {
      dbug_isnt ( $func, "", "Correct function name provided. ($func)" );
   }

   return ($expected);
}


BEGIN {
   DBUG_ENTER_FUNC ();

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $lvl = ( get_fish_state () == -1 ) ? -1 : 1;

   $start_level = test_fish_level ();
   dbug_is ($lvl, $start_level, "In the 4th BEGIN block ...");   # Test # 3
   DBUG_PRINT ("PURPOSE", "\nJust verifying the trace caller & line numbers are good!\nFor all DBUG_ENTER_* & DBUG_PRINT calls.\n.");
   func2();
   $lvl = test_fish_level ();
   dbug_is ($start_level, $lvl, "BEGIN Level Check Worked!");    # Test # 4

   dbug_ok ( dbug_active_ok_test () );
   dbug_ok ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   my $line = ${fish_called_by}->(1);
   validate_line ( $line );                # Tests # 6 & 7.

   DBUG_VOID_RETURN ();
}


# No calls to ok() or ok9() unless failures in the END block!
END {
   DBUG_ENTER_FUNC (@_);

   func2();

   my $lvl = test_fish_level ();
   if ( $start_level != $lvl ) {
      dbug_ok (0, "END Level Check Worked!");
   }

   DBUG_VOID_RETURN ();
}

my $anon_func1 = sub { DBUG_ENTER_FUNC (@_); func2 (); DBUG_PRINT ("TEST", "Test Func."); DBUG_VOID_RETURN (); };

my $anon_func2 = sub {
                       DBUG_ENTER_FUNC (@_);
                       func2 ();
                       DBUG_PRINT ("TEST", "Test Func.");
                       DBUG_VOID_RETURN ();
                     };

my $root;
my $indirect_value = "";

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   $root = DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");

   # Tests the low level functions ...
   dbug_ok (1, '-'x60);

   if ( 1 ) {
      dbug_ok (1, "IF (test)");
   } else {
      dbug_ok (1, "ELSE (test)");
   }

   # Correct way to call it ...
   my $line = ${fish_called_by}->(1);
   validate_line ( $line );

   # Incorrect way to call it ...
   $line = get_fish_module()->_dbug_called_by (1);
   validate_line ( $line );

   low_level_test_1 ();
   low_level_test_eval_1 ();
   low_level_test_eval_2 ();
   low_level_test_2 ();
   low_level_test_eval_3 ();

   # Strange failure tests ...
   dbug_ok (1, '-'x60);

   # Comment out the following 2 functions once issues resolved ...
   # no_such_function ();
   # no_such_func_called_1 ();

   # Change to 1 once program is debugged.
   dbug_ok (1, "Passed Die/Warn Tests.");

   eval {
      no_such_function ();
   };
   eval {
      no_such_func_called_1 ();
   };
   if ($@) {
      DBUG_CATCH ();
   }
   no_such_func_called_2 ();
   eval {
      die ("Hello World!\n");    # Suppress line numbers.
   };
   eval {
      die ("Good Bye World!");      # Want line numbers.
   };

   warn ("Skip - No line numbers.\n");
   warn ("Skip - Has line numbers.");

   # Tests at a higher level ...
   dbug_ok (1, '-'x60);
   func1();
   block_test();
   eval_test();
   eval_block_test();

   # DBUG_RETURN_SPECIAL tests ...
   indirect_test ( "no return value expected." );
   dbug_is ($indirect_value, "", "Void return didn't call the indirect_call()");

   my $i = indirect_test ( "scalar return value expected." );
   dbug_ok ($indirect_value ne "" && $indirect_value eq $i, "The indirect_call() returned the correct value!");

   my @i = indirect_test ( "list return value expected." );
   my $cnt = @i;
   dbug_ok ($indirect_value eq "" && $cnt == 4, "List return didn't call the indirect_call() & returned the right list.");

   DBUG_PRINT ("INFO", "This is a test line!");
   level_test();

   # Calling an anonymous function to test how it works!
   $anon_func1->( qw / a b c / );
   dbug_ok (1, "Anonymous function called.");
   $anon_func2->( qw / a b c / );
   dbug_ok (1, "Anonymous function called.");

   DBUG_PRINT ("INFO", "--------------------------------------------------");
   if ( $try_tiny_flag ) {
      my $res = try_tiny_test ( qw / x y z / );
      dbug_is ($res, 3, "The try/catch/finally test worked with Tiny::Try!");
   } else {
      dbug_ok (1, "Tiny::Try not installed.  Skipping try/catch/finally test.");
   }

   my $extra;
   if ( $test_obj_flag ) {
      DBUG_PRINT ("INFO", "--------------------------------------------------");
      test_my_object_1 ();
      DBUG_PRINT ("INFO", "--------------------------------------------------");
      $extra = test_my_object_2 ();
   } else {
      dbug_ok (1, "The test_object module has isues.  Skipping these tests.");
      $extra = "Junk Food!";
   }

   my $lvl = test_fish_level ();
   dbug_is ($start_level, $lvl, "MAIN Level Check Worked!");

   # Tells Test::More we are done!
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
# The crappy die tests ...
# -----------------------------------------------
sub no_such_func_called_1
{
   DBUG_ENTER_FUNC (@_);
   no_such_function ();
   DBUG_RETURN ( "Nothing!" );
}

sub no_such_func_called_2
{
   DBUG_ENTER_FUNC (@_);
   eval {
      no_such_function ();
   };
   DBUG_RETURN ( "Something!" );
}

# -----------------------------------------------
# Low level tests via private method ...
# -----------------------------------------------
# Assumes called the next line after _dbug_called_by() or ${fish_caleld_by}->() call.
sub low_level_test_1
{
   DBUG_ENTER_FUNC (@_);

   # Emulates DBUG_ENTER_BLOCK() & DBUG_PRINT() ...
   my $line = ${fish_called_by}->(1);
   my $cnt = validate_line ($line) + 3;

   $line = DBUG_PRINT ("TEST", "Checking line number!  (Should be %d)", $cnt);
   # validate_line ($line);    # Doesn't work yet ...

   # Emulates DBUG_ENTER_FUNC() ... (who called low_level_test_1)
   $line = ${fish_called_by}->(1, 1);
   validate_line ($line, $root, (caller(0))[2]);

   DBUG_VOID_RETURN ();
}

sub low_level_test_2
{
   my $f = DBUG_ENTER_FUNC (@_);
   my $line = ${fish_called_by}->(1);
   validate_line ($line);
   {
      DBUG_ENTER_BLOCK ("Hopeless");
      $line = ${fish_called_by}->(1);
      validate_line ($line, $f);
      DBUG_VOID_RETURN ();
   }
   DBUG_VOID_RETURN ();
}

sub low_level_test_eval_1
{
   DBUG_ENTER_FUNC (@_);
   eval {
      # This is a dummy comment ...
      my $line = ${fish_called_by}->(1);
      validate_line ($line);
   };
   DBUG_VOID_RETURN ();
}

sub low_level_test_eval_2
{
   DBUG_ENTER_FUNC (@_);
   eval {
      # This is a dummy comment ...
      eval {
         # This is a dummy comment ...
         my $msg = "This is a dummy message!";
         my $line = ${fish_called_by}->(1);
         validate_line ($line);
      };
   };
   DBUG_VOID_RETURN ();
}

sub low_level_test_eval_3
{
   my $f = DBUG_ENTER_FUNC (@_);
   eval {
      DBUG_ENTER_FUNC ();
      eval {
         DBUG_ENTER_BLOCK ("fun");
         # This is a dummy comment ...
         my $msg = "This is a dummy message!";
         my $line = ${fish_called_by}->(1);
         validate_line ($line, $f);
         DBUG_VOID_RETURN ()
      };
      DBUG_VOID_RETURN ()
   };
   DBUG_VOID_RETURN ();
}


# -----------------------------------------------
# The real test functions ...
# Must manually look at the fish logs to validate the results!
# -----------------------------------------------
sub level_test
{
   DBUG_ENTER_FUNC (@_);
   DBUG_PRINT ("INFO", "Another test line!");
   DBUG_VOID_RETURN ();
}

sub func1
{
   DBUG_ENTER_FUNC (@_);
   func2();
   func2();
   func3();
   DBUG_VOID_RETURN ();
}

sub func3
{
   DBUG_ENTER_FUNC (@_);

   if (1==1) {
      DBUG_ENTER_BLOCK ("nameless");
      dbug_ok (1, "Nameless block test!");
      DBUG_VOID_RETURN ();
   }

   DBUG_VOID_RETURN ();
}

sub block_test
{
   DBUG_ENTER_BLOCK ("block_testing");
   dbug_ok (1, "Block test without FUNC!");
   DBUG_VOID_RETURN ();
}

sub eval_test
{
   DBUG_ENTER_FUNC (@_);
   eval {
      DBUG_ENTER_FUNC ();
      func2();
      dbug_ok (1, "Eval test!");
      eval {
         DBUG_ENTER_FUNC ();
         func2();
         dbug_ok (1, "Eval test 2!");
         DBUG_VOID_RETURN ();
      };
      DBUG_VOID_RETURN ();
   };
   DBUG_VOID_RETURN ();
}

# All block calls give this function as it's caller!
sub eval_block_test
{
   DBUG_ENTER_BLOCK ("eval_block_testing");
   eval {
      DBUG_ENTER_BLOCK ("**EVAL**");
      func2();
      dbug_ok (1, "Eval block test!");
      eval {
         DBUG_ENTER_BLOCK ("***EVAL 2***");
         func2();
         dbug_ok (1, "Eval test 2!");
         DBUG_VOID_RETURN ();
      };
      DBUG_VOID_RETURN ();
   };
   DBUG_VOID_RETURN ();
}

sub indirect_test
{
   DBUG_ENTER_FUNC (@_);
   $indirect_value = "";
   DBUG_RETURN_SPECIAL ( \&indirect_call, "a", "b", "c", "d" );
}

# This function needs to be called via DBUG_RETURN_SPECIAL()
# to test out the desired features.
sub indirect_call
{
   DBUG_ENTER_FUNC (@_);
   $indirect_value = "Return One Value!";
   DBUG_RETURN ( $indirect_value );
}

sub try_tiny_test
{
   DBUG_ENTER_FUNC (@_);

   my $cnt = 0;

   try {
      DBUG_ENTER_FUNC ("TRY-TRY-TRY-TRY");
      ++$cnt;
      die ("Called die in try block!\n");
      DBUG_VOID_RETURN ();
   } catch {
      DBUG_CATCH ();
      DBUG_ENTER_FUNC ("CATCH-CATCH-CATCH-CATCH");
      ++$cnt;
      print_stack_trace ("In the Catch Block ...");
      DBUG_VOID_RETURN ();
   } finally {
      DBUG_ENTER_FUNC ("FINALLY-FINALLY-FINALLY-FINALLY");
      ++$cnt;
      print_stack_trace ("In the Finally Block ...");
      DBUG_VOID_RETURN ();
   };

   DBUG_RETURN ( $cnt );
}


sub test_my_object_1
{
   DBUG_ENTER_FUNC (@_);

   # my $obj = test_object->new ("Destroyed on Return!");
   # dbug_ok ( defined $obj, "Test Object was created!");
   my @args;
   push (@args, "Destroyed on Return!");
   my $obj = dbug_new_ok ('test_object' => \@args);

   my $res = $obj->talk ("Talk to me!");
   dbug_ok ( $res, "Was able to call method in object!");

   $res = $obj->no_such_function ("Why should I talk to you?");
   dbug_ok ( $res, "Was able to call a non-existant method in object!");

   DBUG_VOID_RETURN ();
   # The DESTROY method was called here!
}

sub test_my_object_2
{
   DBUG_ENTER_FUNC (@_);

   my $extra = test_object->new ("Deferred destruction!");

   if ( 1 == 1 ) {
      my $obj = test_object->new ("Destroyed in 'if' block!");
      dbug_ok ( defined $obj, "Test Object was created!");

      my $res = $obj->talk ("Talk to me!");
      dbug_ok ( $res, "Was able to call method in object!");
   }
   # The DESTROY method was called here for $obj!

   DBUG_RETURN ( $extra );
   # The DESTROY method for $extra was called after DBUG_LEAVE !!!
   # When the return value went out of scope!
}

