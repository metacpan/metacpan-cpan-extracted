
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/PluginBundle/Author/RUSSOZ.pm',
    'lib/Pod/Weaver/PluginBundle/Author/RUSSOZ.pm',
    't/00-compile.t',
    't/00-load.t',
    't/000-report-versions-tiny.t',
    't/placeholder.t'
);

notabs_ok($_) foreach @files;
done_testing;
