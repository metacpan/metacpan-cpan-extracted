#!/usr/bin/perl
use Test::More tests => 3;

use File::Media::Sort qw(media_sort);


is(
  (media_sort(q{tv}, qw(Uppdrag.Granskning.S21E02.SWEDiSH.PDTV.XviD-D2V)))[0],
  q{Uppdrag.Granskning.S21E02.SWEDiSH.PDTV.XviD-D2V}, q{TV OK},
);

is(
  (media_sort('mvids', qw(Shapeshifter-Twin_Galaxies-x264-2010-FRAY)))[0],
  q{Shapeshifter-Twin_Galaxies-x264-2010-FRAY}, q{MVID OK},
);

is(
  (media_sort('music', qw(VA_-_Modern_80s__The_Best_Of_Discopop_Volume_1-2CD-1998-HB)))[0],
  q{VA_-_Modern_80s__The_Best_Of_Discopop_Volume_1-2CD-1998-HB}, q{MUSIC OK},
);
