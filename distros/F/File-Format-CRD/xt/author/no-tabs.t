use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
