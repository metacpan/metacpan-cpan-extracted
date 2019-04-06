use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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
    't/lib/File/Find/Object/TreeCreate.pm',
    't/release-trailing-space.t',
    't/sample-data/to-copy-from/File-Find-Rule.txt',
    't/sample-data/to-copy-from/findorule.txt',
    't/sample-data/to-copy-from/foobar',
    't/sample-data/to-copy-from/lib/File/Find/Object/Rule/Test/ATeam.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
