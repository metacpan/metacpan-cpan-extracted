use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/dir-dump',
    'lib/File/Dir/Dumper.pm',
    'lib/File/Dir/Dumper/App.pm',
    'lib/File/Dir/Dumper/Base.pm',
    'lib/File/Dir/Dumper/DigestCache/Dummy.pm',
    'lib/File/Dir/Dumper/DigestCache/FS.pm',
    'lib/File/Dir/Dumper/Scanner.pm',
    'lib/File/Dir/Dumper/Stream/JSON/Reader.pm',
    'lib/File/Dir/Dumper/Stream/JSON/Writer.pm',
    't/00-compile.t',
    't/00-load.t',
    't/boilerplate.t',
    't/dumper.t',
    't/lib/File/Find/Object/TreeCreate.pm',
    't/sample-data/placeholder.txt',
    't/script.t',
    't/test-stream.t',
    't/unit--dummy-digest-cache.t',
    't/unit--fs-digest-cache.t'
);

notabs_ok($_) foreach @files;
done_testing;
