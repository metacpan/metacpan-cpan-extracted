use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/NoSmartCommentsTests.pm',
    'lib/Dist/Zilla/Plugin/Test/NoSmartComments.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/develop-requires.t',
    't/develop-requires.t~',
    't/file-is-generated.t',
    't/file-is-generated.t~'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
