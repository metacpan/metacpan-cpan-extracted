#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.005

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/HashData/Array.pm','lib/HashData/DBI.pm','lib/HashData/Hash.pm','lib/HashData/Test/Source/Array.pm','lib/HashData/Test/Source/DBI.pm','lib/HashData/Test/Source/Hash.pm','lib/HashData/Test/Source/LinesInDATA.pm','lib/HashDataRole/Source/Array.pm','lib/HashDataRole/Source/DBI.pm','lib/HashDataRole/Source/Hash.pm','lib/HashDataRole/Source/LinesInDATA.pm','lib/HashDataRoles/Standard.pm'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
