use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

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

notabs_ok($_) foreach @files;
done_testing;
