use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/IO/Pty/Easy.pm',
    't/00-compile.t',
    't/open-close.t',
    't/read-write.t',
    't/spawn.t',
    't/subprocess.t',
    't/system.t',
    't/undefined-program.t'
);

notabs_ok($_) foreach @files;
done_testing;
