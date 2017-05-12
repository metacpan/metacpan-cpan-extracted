use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/googlecode_upload.pl',
    'lib/Google/Code/Upload.pm',
    't/00-compile.t',
    't/load.t',
    't/testfile.1',
    't/testfile.2',
    't/upload.t'
);

notabs_ok($_) foreach @files;
done_testing;
