#!/usr/bin/perl

use strict;
use warnings;

use Test::More 0.88;
use File::Spec;

use Fred::Fish::DBUG::Test;
BEGIN { push (@INC, File::Spec->catdir (".", "t", "off")); }
use helper1234;

# Program:  35-eval_auto_balance.t
# This test program tests out not using DBUG_CATCH() to recover balancing the
# fish stack.

my $start_level;

sub my_warn
{
   dbug_ok (0, "There were no unexpected warnings!");
}

BEGIN {
   # Can't use any of the constants defined by this module
   # unless we use them in a separate BEGIN block!

   my $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   unless (use_ok ('Fred::Fish::DBUG', @opts)) {
      dbug_BAIL_OUT ( "Can't load $fish_module via Fred::Fish::DBUG qw /" .
                      join (" ", @opts) . " /" );
   }

   dbug_ok (1, "Used options qw / " . join (" ", @opts) . " /");

   unless (use_ok ( "Fred::Fish::DBUG::Signal" )) {         # Test # 4
      dbug_BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
  }
}

BEGIN {
   # So can detect if the module generates any warnings ...
   DBUG_TRAP_SIGNAL ( "__WARN__", DBUG_SIG_ACTION_LOG, \&my_warn );

   # -1 OFF module, 0 turn fish on, 1 turn fish off.
   my $off = ( get_fish_state () == 1 ) ? 1 : 0;

   DBUG_PUSH ( get_fish_log(), off => $off );

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level_no_warn (1);

   my $a = dbug_ok (1, "In the BEGIN block ...");

   my $lvl = test_fish_level_no_warn (1);
   dbug_is ( $lvl, $start_level, "Begin Block Level Check" );

   dbug_ok ( dbug_active_ok_test () );

   dbug_ok ( 1, "Fish File: " . DBUG_FILE_NAME () );

   DBUG_VOID_RETURN ();
}

# -----------------------------------------------------------------
sub result
{
   DBUG_ENTER_FUNC (@_);
   my ($name, $line, $file) = (caller(0))[3,2,1];
   my $i = 0;
   while ( defined $name && $name ne "(eval)" ) {
      ($name, $line, $file) = (caller(++$i))[3,2,1];
      # print "Found: ${name}, ${line}, ${file}\n";
   }

   if ( defined $name && $name eq "(eval)" ) {
      DBUG_PRINT ("INFO", "Idx: $i - Eval is on line $line in file $file\n");
   } else {
      DBUG_PRINT ("INFO", "There is no eval to track!\n");
   }

   DBUG_VOID_RETURN ();
}

sub none
{
   DBUG_ENTER_FUNC (@_);
   die ("It's just not worth it!\n");
   result ();
   DBUG_VOID_RETURN ();
}

sub some
{
   DBUG_ENTER_FUNC (@_);
   eval {
      DBUG_ENTER_FUNC();
      result ();
      die ("It's just not worth it!\n");
      DBUG_VOID_RETURN();
   };
   if ( $@ ) {
      die ($@);
   }
   DBUG_VOID_RETURN ();
}

sub twice
{
   DBUG_ENTER_FUNC (@_);
   eval {
      DBUG_ENTER_FUNC();
      some ();
      DBUG_VOID_RETURN();
   };
   if ( $@ ) {
      DBUG_CATCH ();
      die ($@);
   }
   DBUG_VOID_RETURN ();
}

# -----------------------------------------------------------------
sub check_depth
{
   DBUG_ENTER_FUNC ();
   my $expected_lvl = shift;                # Expected ...
   my $deep = shift;

   my $lvl = test_fish_level_no_warn ($expected_lvl);   # Actual ...

   unless ($lvl == $expected_lvl) {
      dbug_ok (0, "check_depth($expected_lvl) fish level is good ($lvl)");
   }

   my $depth = $deep ? "deep": "shallow";
   die ("How ${depth} can we go?\n");
   DBUG_VOID_RETURN ();
}

# -----------------------------------------------------------------
# Demonstrates failue of autobalancing without using DBUG_CATCH()!
# Looks like recursion in the fish logs ...
# -----------------------------------------------------------------
sub repeat_broken_1
{
   DBUG_ENTER_FUNC (@_);
   foreach (0..5) {
      eval {
         DBUG_ENTER_FUNC ();
         die ("Repeatable error!\n");
         DBUG_VOID_RETURN ();
      };
   }
   DBUG_VOID_RETURN ();     # Forces the auto-balancing ...
}

# -----------------------------------------------------------------
# Demonstrates the fish problem again!
# -----------------------------------------------------------------
sub repeat_broken_2
{
   DBUG_ENTER_FUNC (@_);
   my $lvl = test_fish_level_no_warn (1);
   foreach (0..5) {
      eval {
         check_depth ($lvl + $_ + 1, 1);
      };
   }
   DBUG_VOID_RETURN ();     # Forces the auto-balancing ...
}

# -----------------------------------------------------------------
# Demonstrates how DBUG_CATCH() must be used in this case!
# -----------------------------------------------------------------
sub repeat_fixed_1
{
   DBUG_ENTER_FUNC (@_);
   foreach (0..5) {
      eval {
         DBUG_ENTER_FUNC ();
         die ("Repeatable fixed!\n");
         DBUG_VOID_RETURN ();
      };
      if ( $@ ) {
          DBUG_CATCH ();
      }
   }
   DBUG_VOID_RETURN ();
}

# -----------------------------------------------------------------
# Demonstrates the need for the fix again!
# -----------------------------------------------------------------
sub repeat_fixed_2
{
   DBUG_ENTER_FUNC (@_);
   my $lvl = test_fish_level_no_warn (1);
   foreach (0..5) {
      eval {
         check_depth ($lvl + 1, 0);
      };
      if ( $@ ) {
          DBUG_CATCH ();
      }
   }
   DBUG_VOID_RETURN ();
}


# -----------------------------------------------------------------
# The main program ...
# -----------------------------------------------------------------
{
   DBUG_ENTER_FUNC ();

   eval {
      DBUG_ENTER_FUNC();
      my $eval_level = test_fish_level_no_warn (2);

      eval {
         DBUG_ENTER_FUNC();
         result ();
         none ();
         DBUG_VOID_RETURN();
      };

      DBUG_PRINT ("INFO", "Rebalanced ...");
      my $lvl = test_fish_level_no_warn (2);
      dbug_is ( $lvl, $eval_level, "DBUG_PRINT call rebalanced the fish logs!" );

      eval {
         DBUG_ENTER_FUNC();
         result ();
         some ();
         DBUG_VOID_RETURN();
      };

      eval {
         DBUG_ENTER_FUNC();
         result ();
         none ();
         DBUG_VOID_RETURN();
      };

      eval {
         DBUG_ENTER_FUNC();
         result ();
         twice ();
         DBUG_VOID_RETURN();
      };
      eval {
         DBUG_ENTER_BLOCK("LAST");
         result ();
         none ();
         DBUG_VOID_RETURN();
      };

      DBUG_VOID_RETURN();
   };

   result ();
   my $lvl = test_fish_level_no_warn (1);
   dbug_is ( $lvl, $start_level, "result call rebalanced the fish logs!" );

   DBUG_PRINT ("END-EVAL", "="x40);
   repeat_broken_1 ();
   $lvl = test_fish_level_no_warn (1);
   dbug_is ( $lvl, $start_level, "repeat_broken_1 call eventually rebalanced the fish logs!" );
   DBUG_PRINT ("END-EVAL", "-"x40);
   repeat_fixed_1 ();
   $lvl = test_fish_level_no_warn (1);
   dbug_is ( $lvl, $start_level, "repeat_fixed call rebalanced the fish logs correctly!" );
   DBUG_PRINT ("END-EVAL", "="x40);
   repeat_broken_2 ();
   $lvl = test_fish_level_no_warn (1);
   dbug_is ( $lvl, $start_level, "repeat_broken_2 call eventually rebalanced the fish logs!" );
   DBUG_PRINT ("END-EVAL", "-"x40);
   repeat_fixed_2 ();
   $lvl = test_fish_level_no_warn (1);
   dbug_is ( $lvl, $start_level, "repeat_fixed call rebalanced the fish logs correctly!" );
   DBUG_PRINT ("END-EVAL", "="x40);

   DBUG_PRINT ("INFO", "First call outside of an eval block!");
   eval {
      DBUG_ENTER_BLOCK("EVAL");
      die ("Never call the return!\n");
      DBUG_VOID_RETURN();
   };
   DBUG_PRINT ("INFO", "Calling DBUG_LEAVE!");
   eval {
      DBUG_ENTER_FUNC();
      die ("Never call the return!\n");
      DBUG_VOID_RETURN();
   };

   # We didn't use dbug_ok/dbug_is here on purpose, it's not a bug!
   # We don't want to write this result to fish, it would break the
   # test of DBUG_LEAVE fixing things.
   $lvl = test_fish_level_no_warn (2);
   ok ( $lvl > $start_level, "The fish logs are not balanced yet ... ($lvl vs $start_level)" );
   ok ( 1, "Examine the fish log file to verify everything was balanced!");

   done_testing ();

   DBUG_LEAVE (0);
}

