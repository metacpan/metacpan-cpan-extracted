use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/File/Find/utf8.pm',
    't/00-compile.t',
    't/find.t',
    't/import.t',
    't/utf8_check.t',
    't/warning_levels.t'
);

notabs_ok($_) foreach @files;
done_testing;
