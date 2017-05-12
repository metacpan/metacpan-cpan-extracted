#!/usr/bin/perl

use strict;
use diagnostics;

use Unicode::String qw / utf8 /;
use IETF::ACE qw / UCS4toRACE /;

   my $TheIn="ábcde"; # .com

   my $TheUCS4 = utf8($TheIn)->ucs4;

   my $TheOut = &UCS4toRACE($TheUCS4);

   print <<EOD;
Latin1 Input = $TheIn.com
RACE Output = $TheOut.com
EOD

