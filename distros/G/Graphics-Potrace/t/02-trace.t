# vim: filetype=perl :
use strict;
use warnings;
use English qw( -no_match_vars );

#use Test::More tests => 1; # last test to print
use Test::More 'no_plan';  # substitute with previous line when done

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
   vectorial => ['Svg', file => \my $svg]
);

isa_ok($vector, 'Graphics::Potrace::Vectorial');
ok(defined($svg), 'svg is defined');
ok(length($svg), 'svg is not empty');
like($svg, qr{<svg}, 'should contain an SVG document');
my $count =()= $svg =~ m{<path}gmxs;
is($count, 2, 'it has two paths');
