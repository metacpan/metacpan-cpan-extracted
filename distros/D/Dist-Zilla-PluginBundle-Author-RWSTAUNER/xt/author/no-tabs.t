use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/MintingProfile/Author/RWSTAUNER.pm',
    'lib/Dist/Zilla/PluginBundle/Author/RWSTAUNER.pm',
    'lib/Dist/Zilla/PluginBundle/Author/RWSTAUNER/Minter.pm',
    'lib/Pod/Weaver/PluginBundle/Author/RWSTAUNER.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/configure.t',
    't/lib/Dist/Zilla/Plugin/No_Op_Releaser.pm',
    't/mint.t'
);

notabs_ok($_) foreach @files;
done_testing;
