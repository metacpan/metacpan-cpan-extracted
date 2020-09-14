use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/TravisCI/StatusBadge.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/02-distmeta.t',
    't/03-anyreadme.t',
    't/lib/Builder.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
