use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/App/Command/policies.pm',
    'lib/Dist/Zilla/Plugin/Software/Policies.pm',
    'lib/Dist/Zilla/Plugin/Test/Software/Policies.pm',
    't/00-load.t'
);

notabs_ok($_) foreach @files;
done_testing;
