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

my $filenames = ['lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Black.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Blue.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Brown.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Gray.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Green.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Orange.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Pink.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Purple.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Red.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/White.pm','lib/Graphics/ColorNamesCMYK/ToutesLesCouleursCom/Yellow.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
