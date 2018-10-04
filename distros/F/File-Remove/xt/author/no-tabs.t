use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/File/Remove.pm',
    't/00-compile.t',
    't/01_compile.t',
    't/02_directories.t',
    't/03_deep_readonly.t',
    't/04_can_delete.t',
    't/05_links.t',
    't/06_curly.t',
    't/07_cwd.t',
    't/08_spaces.t',
    't/09_fork.t',
    't/10_noglob.t'
);

notabs_ok($_) foreach @files;
done_testing;
