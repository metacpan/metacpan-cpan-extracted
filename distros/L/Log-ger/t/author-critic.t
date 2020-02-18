#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.003

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/Log/ger.pm','lib/Log/ger/Format.pm','lib/Log/ger/Format/None.pm','lib/Log/ger/Heavy.pm','lib/Log/ger/Layout.pm','lib/Log/ger/Output.pm','lib/Log/ger/Output/Array.pm','lib/Log/ger/Output/ArrayML.pm','lib/Log/ger/Output/Null.pm','lib/Log/ger/Output/String.pm','lib/Log/ger/Plugin.pm','lib/Log/ger/Plugin/MultilevelLog.pm','lib/Log/ger/Util.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
