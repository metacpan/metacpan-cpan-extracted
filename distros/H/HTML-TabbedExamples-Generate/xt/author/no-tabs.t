use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTML/TabbedExamples/Generate.pm',
    't/00-compile.t',
    't/tabbed-examples-gen.t'
);

notabs_ok($_) foreach @files;
done_testing;
