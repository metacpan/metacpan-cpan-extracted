use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/CheckChangesTests.pm',
    'lib/Dist/Zilla/Plugin/Test/CheckChanges.pm',
    't/00-compile.t',
    't/deprecated.t',
    't/everything.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
