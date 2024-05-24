#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Black.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Blue.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Brown.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Gray.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Green.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Orange.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Pink.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Purple.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Red.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/White.pm','lib/HashData/ColorCode/CMYK/ToutesLesCouleursCom/Yellow.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
