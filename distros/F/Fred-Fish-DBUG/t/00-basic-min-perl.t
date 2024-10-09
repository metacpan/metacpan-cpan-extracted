#!/user/bin/perl

# Program:  00-basic-min-perl.t
#   Does a very basic perl version test.

use strict;
use warnings;

use Test::More tests => 1;

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   my $ver = $];
   my $min_ver = 5.014000;   # 5.14.0

   $min_ver = 5.008008;   # Temp at 5.8.8

   my $good = ($min_ver <= $ver) ? 1 : 0;

   ok ($good, "perl ${ver} is later than version ${min_ver}");

   unless ( $good ) {
      BAIL_OUT ("You must be runing version ${min_ver} or later to use this module!");
   }

   exit (0);
}

# -----------------------------------------------

