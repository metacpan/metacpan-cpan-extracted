#!/user/bin/perl

# Program:  07-basic-signalkiller.t
# Just verifies that Fred::Fish::DBUG::Signal can be used ...

use strict;
use warnings;

use Test::More tests => 5;

BEGIN {
   unless (use_ok ("Fred::Fish::DBUG::ON")) {
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::ON" );
      exit (0);
   }

   unless (use_ok ("Fred::Fish::DBUG::Signal")) {
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::Signal" );
      exit (0);
   }
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   # By default this won't work without SignalKiller ...
   DBUG_TRAP_SIGNAL ("__DIE__", DBUG_SIG_ACTION_LOG );

   # Test # 3
   ok (1, "The module loaded OK.");

   # Test # 4
   my $sts = 1;
   eval {
      die ("This die message should be ignored!\n");
      ok (0, "Die was ignored!  Failure!");
      $sts = 0;
   };
   if ( $sts ) {
      ok (1, "Die wasn't ignored!");
   }

   DBUG_TRAP_SIGNAL ("__DIE__", DBUG_SIG_ACTION_DIE );

   # Test # 5
   $sts = 1;
   eval {
      die ("This die message should be trapped!\n");
      ok (0, "Die was trapped!");
      $sts = 0;
   };
   if ( $sts ) {
      ok (1, "Die was trapped!");
   }
}

