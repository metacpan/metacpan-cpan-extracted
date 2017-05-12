use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.18

use Test::More 0.88;
use Test::EOL;

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

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
