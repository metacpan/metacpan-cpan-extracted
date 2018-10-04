use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
