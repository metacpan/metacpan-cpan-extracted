#!/opt/perl/bin/perl 
use strict;
use warnings;
use English qw( -no_match_vars );
use Data::Dumper;
$Data::Dumper::Indent = 1;

use lib qw( lib blib/lib blib/arch );
use lib qw( ../lib );
use Graphics::Potrace qw< trace >;

my $vector = trace(
   raster => [
      Ascii => data => '

                           oo"""""""MM
               ooooooo  ooM"          Moo
             oMM"    ""oM"              "Moo
             MM  o  oMM"""Moo           oMMMM
            MM" "" MM"""   "MM oo ooo ooMMMMMMo
             "MM  MM  Moo  oMM "MMMMMMMMMoMMMMMMo
             oMMMM MM   ooMM"   "MMMM"MMM MMMMMMMM
        ooM""""      """""       MMMMo"MMo"MMM"MMMMMo
      oMM"                       "MMMMo"MMoMM" "MM""Moo
    oMM"         oo               MM"MMo"MMMMM  MMo "MM
  MMM          oMMM       oMM     MM "MMoMM"MMo  MMo "M"
 MMM       ooMMMM"       oM"M         MMMMM MMM   "
 MMM    ooMM""""MM     oM"  MM        MM"MMM"""
  """M""""      MMooMMM"   oMM       o   MM"
                 """"      MM       MM
                        ooMM"      MM"
                      MMM""        MM
                      ""MMo       MM
                         "MMo    MMM
                                 MM"
                                MMM

'
   ],
   vectorial => ['Svg', fh => \*STDOUT]
);
