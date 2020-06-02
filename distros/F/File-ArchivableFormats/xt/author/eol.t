use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/ArchivableFormats.pm',
    'lib/File/ArchivableFormats/Plugin.pm',
    'lib/File/ArchivableFormats/Plugin/DANS.pm',
    't/00-compile.t',
    't/100-fileformats.t',
    't/100-mimetypes.t',
    't/200-dans.t',
    't/300-path-tiny.t',
    't/data/README',
    't/data/README.md'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
