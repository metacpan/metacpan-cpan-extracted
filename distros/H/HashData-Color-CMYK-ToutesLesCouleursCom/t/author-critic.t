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

my $filenames = ['lib/HashData/Color/CMYK/ToutesLesCouleursCom.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Black.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Blue.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Brown.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Gray.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Green.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Orange.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Pink.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Purple.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Red.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/White.pm','lib/HashData/Color/CMYK/ToutesLesCouleursCom/Yellow.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
