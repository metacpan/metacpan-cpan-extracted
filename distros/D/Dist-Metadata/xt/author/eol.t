use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Metadata.pm',
    'lib/Dist/Metadata/Archive.pm',
    'lib/Dist/Metadata/Dir.pm',
    'lib/Dist/Metadata/Dist.pm',
    'lib/Dist/Metadata/Struct.pm',
    'lib/Dist/Metadata/Tar.pm',
    'lib/Dist/Metadata/Zip.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/archive.t',
    't/determine.t',
    't/dir.t',
    't/dists.t',
    't/file_spec.t',
    't/load_meta.t',
    't/module_info.t',
    't/no_index.t',
    't/package_versions.t',
    't/struct.t',
    't/tar.t',
    't/zip.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
