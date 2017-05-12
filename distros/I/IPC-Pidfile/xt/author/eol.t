use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.17

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/IPC/Pidfile.pm',
    't/pidfile.t',
    't/sleeper.pl',
    't/sleeper.pl.pid'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
