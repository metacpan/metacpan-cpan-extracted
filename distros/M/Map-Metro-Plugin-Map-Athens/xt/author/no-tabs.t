use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Map/Metro/Plugin/Map/Athens.pm',
    'lib/Map/Metro/Plugin/Map/Athens/Lines.pod',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t'
);

notabs_ok($_) foreach @files;
done_testing;
