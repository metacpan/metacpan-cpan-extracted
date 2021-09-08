use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/findorule',
    'lib/File/Find/Object/Rule.pm',
    'lib/File/Find/Object/Rule/Extending.pod',
    'lib/File/Find/Object/Rule/Procedural.pod',
    't/00-compile.t',
    't/File-Find-Rule.t',
    't/findorule.t',
    't/foobar',
    't/lib/File/Find/Object/Rule/Test/ATeam.pm',
    't/release-trailing-space.t',
    't/sample-data/to-copy-from/File-Find-Rule.txt',
    't/sample-data/to-copy-from/findorule.txt',
    't/sample-data/to-copy-from/foobar',
    't/sample-data/to-copy-from/lib/File/Find/Object/Rule/Test/ATeam.pm'
);

notabs_ok($_) foreach @files;
done_testing;
