use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dir/Manifest.pm',
    'lib/Dir/Manifest/Key.pm',
    'lib/Dir/Manifest/Slurp.pm',
    't/00-compile.t',
    't/dir-manifest.t',
    't/slurp.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
