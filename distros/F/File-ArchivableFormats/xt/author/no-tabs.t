use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/File/ArchivableFormats.pm',
    'lib/File/ArchivableFormats/Plugin.pm',
    'lib/File/ArchivableFormats/Plugin/DANS.pm',
    't/00-compile.t',
    't/100-fileformats.t',
    't/100-mimetypes.t',
    't/200-dans.t'
);

notabs_ok($_) foreach @files;
done_testing;
