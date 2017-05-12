use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/HTML/ExtractText.pm',
    't/00-compile.t',
    't/00-load.t',
    't/01-extract.t',
    't/02-subclassing.t',
    't/03-alternate-text-sources.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
