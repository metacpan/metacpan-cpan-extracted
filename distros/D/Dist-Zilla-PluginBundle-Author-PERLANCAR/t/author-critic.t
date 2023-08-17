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

my $filenames = ['lib/Dist/Zilla/Plugin/PERLANCAR/BeforeBuild.pm','lib/Dist/Zilla/PluginBundle/Author/PERLANCAR.pm','lib/Dist/Zilla/PluginBundle/Author/PERLANCAR/NonCPAN.pm','lib/Dist/Zilla/PluginBundle/Author/PERLANCAR/NonCPAN/Task.pm','lib/Dist/Zilla/PluginBundle/Author/PERLANCAR/Task.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
