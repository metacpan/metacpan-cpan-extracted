use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Dist/Zilla/Plugin/UploadToStratopan.pm',
    't/00-compile.t',
    't/stratopan.t'
);

notabs_ok($_) foreach @files;
done_testing;
