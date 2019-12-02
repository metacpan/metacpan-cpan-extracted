use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/Slurp.pm',
    't/00-report-prereqs.t',
    't/01-error_edit_file.t',
    't/01-error_edit_file_lines.t',
    't/01-error_prepend_file.t',
    't/01-error_read_dir.t',
    't/01-error_read_file.t',
    't/01-error_write_file.t',
    't/append_null.t',
    't/binmode.t',
    't/data_section.t',
    't/edit_file.t',
    't/error.t',
    't/file_object.t',
    't/handle.t',
    't/inode.t',
    't/large.t',
    't/lib/FileSlurpTest.pm',
    't/lib/FileSlurpTestOverride.pm',
    't/newline.t',
    't/no_clobber.t',
    't/original.t',
    't/paragraph.t',
    't/perms.t',
    't/prepend_file.t',
    't/pseudo.t',
    't/read_dir.t',
    't/slurp.t',
    't/stdin.t',
    't/stringify.t',
    't/tainted.t',
    't/write_file_win32.t',
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
