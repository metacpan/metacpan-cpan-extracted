use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/Author/HAYOBAAN/LinkCheck.pm',
    'lib/Dist/Zilla/Plugin/Author/HAYOBAAN/NextVersion.pm',
    'lib/Dist/Zilla/PluginBundle/Author/HAYOBAAN.pm',
    'lib/Pod/Weaver/PluginBundle/Author/HAYOBAAN.pm',
    'lib/Pod/Weaver/Section/Author/HAYOBAAN/Bugs.pm',
    't/00-compile.t',
    't/hayobaan.t'
);

notabs_ok($_) foreach @files;
done_testing;
