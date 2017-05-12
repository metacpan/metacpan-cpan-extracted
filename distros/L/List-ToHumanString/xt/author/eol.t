use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/List/ToHumanString.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-humanize-list-only.t',
    't/02-pluralize.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
