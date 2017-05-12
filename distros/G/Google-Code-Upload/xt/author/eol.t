use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/googlecode_upload.pl',
    'lib/Google/Code/Upload.pm',
    't/00-compile.t',
    't/load.t',
    't/testfile.1',
    't/testfile.2',
    't/upload.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
