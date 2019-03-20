use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Git/Mailmap.pm',
    't/add_and_to_string.t',
    't/from_string_and_remove.t',
    't/load.t',
    't/verify_and_map.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
