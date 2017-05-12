use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Eval/Closure.pm',
    't/00-compile.t',
    't/basic.t',
    't/canonicalize-source.t',
    't/close-over-nonref.t',
    't/close-over.t',
    't/compiling-package.t',
    't/debugger.t',
    't/description.t',
    't/errors.t',
    't/lexical-subs.t',
    't/memoize.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
