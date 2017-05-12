#!/usr/bin/perl -w

use Test::More;
use strict;
my $tests;

BEGIN
   {
   $tests = 11;
   plan tests => $tests;
   chdir 't' if -d 't';
   use lib '../lib';
   };

SKIP:
  {
  skip( 'Test::Pod not installed on this system', $tests )
    unless do
      {
      eval ("use Test::Pod;");
      $@ ? 0 : 1;
      };
  for my $m (qw[ 
    Info.pm
    TIFF.pm
    Info/BMP.pm
    Info/GIF.pm
    Info/JPEG.pm
    Info/PNG.pm
    Info/PPM.pm
    Info/SVG.pm
    Info/TIFF.pm
    Info/XBM.pm
    Info/XPM.pm
    ])
    {
    pod_file_ok( '../lib/Image/' . $m );
    }
  }

