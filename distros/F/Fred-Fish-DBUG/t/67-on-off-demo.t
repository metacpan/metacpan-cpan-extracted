#!/user/bin/perl

# Program:  67-on-off-demo.t
# This test case makes sure using
#     Fred::Fish::DBUG::ON
# and
#     Fred::Fish::DBUG::OFF
# together in the same program doesn't break things!
# Can't push to CPAN if they don't play together!

use strict;
use warnings;

use Test::More;
use File::Spec;

my $start_level;

sub my_warn
{
   chomp (my $msg = shift);
   ok3 (0, "There was an expected warning! ${msg}");
}

sub ok3
{
   DBUG_ENTER_BLOCK ("Test::More::ok", @_);
   my $status = shift || 0;
   my $msg    = shift;

   my $res = ok ( $status, $msg );
   DBUG_RETURN ($res);
}

my $fish_module;

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

   $fish_module = get_fish_module ();
   my @opts = get_fish_opts ();

   # Not using use_ok() on purpose.  Just a proof of concept
   # on how a module should swap between the two versions
   # of the fish module without using use_ok()!
   # use $fish_module;
   eval "use Fred::Fish::DBUG qw / " . join (" ", @opts) . " /";
   if ( $@ ) {
      bail ( "Can't load ${fish_module} via Fred::Fish::DBUG qw / " .
             join (" ", @opts) . " /" );
   }

   ok (1, "Loaded ${fish_module} using alternate method! " . join (" ", @opts));

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
   my $lvl = ( get_fish_state () == -1 ) ? -1 : 1;

   DBUG_PUSH ( get_fish_log(), off => ${off} );

   my $module;

   # The two conflicting test modules ...
   unless ( use_ok ("on_test") ) {      # This module only uses Fred::Fish::DBUG
      bail ( "Can't load the 'on_test' module!" );
   }
   $module = get_fish_module (__FILE__);
   ok2 ($fish_module eq $module, "Selected correct module ($module vs $fish_module)");

   unless ( use_ok ("off_test") ) {     # This module only uses Fred::Fish::DBUG:OFF
      bail ( "Can't load the 'off_test' module!" );
   }
   $module = get_fish_module (__FILE__);
   ok2 ($fish_module eq $module, "Selected correct module ($module vs $fish_module)");

   $module = get_fish_module ( ON_FILE() );
   ok2 ( $module =~ m/::ON$/, "Statically linked to ON --> $module");
   $module = get_fish_module ( OFF_FILE() );
   ok2 ( $module =~ m/::OFF$/, "Statically linked to OFF --> $module");

   DBUG_ENTER_FUNC ();

   $start_level = test_fish_level ();
   is2 ($start_level, $lvl, "In the BEGIN block ...");
   DBUG_PRINT ("PURPOSE", "\nDemonstrates how to swap between Fred::Fish:DBUG::ON & Fred::Fish::DBUG::OFF in your code!\n.");
   $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "BEGIN Level Check Worked!");

   ok2 ( dbug_active_ok_test () );

   ok2 ( 1, "Fish Log: " . DBUG_FILE_NAME() );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC (@_);
   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   ok2 (1, "In the MAIN program ...");

   DBUG_PRINT ("----", "%s", "="x70);
   ok2 (1, "Calling the ON Module ...");
   ON_PRINT1 (1, 2, 3);
   ON_PRINT2 (4, 5, 6);
   DBUG_PRINT ("----", "%s", "="x70);
   ok2 (1, "Calling the OFF Module ...");
   OFF_PRINT1 (1, 2, 3);
   OFF_PRINT2 (4, 5, 6);
   DBUG_PRINT ("----", "%s", "="x70);
   ok2 (1, "Back to normal operation ...");

   my $lvl = test_fish_level ();
   is2 ($lvl, $start_level, "MAIN Level Check Worked!");

   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------

