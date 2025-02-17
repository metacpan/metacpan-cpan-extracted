use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/Format/CRD.pm',
    'lib/File/Format/CRD/Reader.pm',
    't/00-compile.t',
    't/00-load.t',
    't/boilerplate.t',
    't/cpan-changes.t',
    't/pod-coverage.t',
    't/pod.t',
    't/style-trailing-space.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
