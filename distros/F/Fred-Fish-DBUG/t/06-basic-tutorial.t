#!/user/bin/perl

# Program:  06-basic-tutorial.t
# Just verifies that Fred::Fish::DBUG::Tutorial can be used ...

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
   unless (use_ok ("Fred::Fish::DBUG::Tutorial")) {
      BAIL_OUT ( "Can't load Fred::Fish::DBUG::Tutorial" );
      exit (0);
   }
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   ok (1, "The module loaded OK.  Nothing else to test!");
}

