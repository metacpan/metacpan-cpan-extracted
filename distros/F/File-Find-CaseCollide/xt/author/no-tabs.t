use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/find-case-collisions',
    'lib/File/Find/CaseCollide.pm',
    'lib/Test/File/Find/CaseCollide.pm',
    't/00-compile.t',
    't/obj.t',
    't/test-module.t'
);

notabs_ok($_) foreach @files;
done_testing;
