use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Format/JSON/Stream.pm',
    'lib/Format/JSON/Stream/Reader.pm',
    'lib/Format/JSON/Stream/Writer.pm',
    't/00-compile.t',
    't/test-stream.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
