use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
