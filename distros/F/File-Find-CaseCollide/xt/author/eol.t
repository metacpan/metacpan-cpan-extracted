use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/find-case-collisions',
    'lib/File/Find/CaseCollide.pm',
    'lib/Test/File/Find/CaseCollide.pm',
    't/00-compile.t',
    't/obj.t',
    't/test-module.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
