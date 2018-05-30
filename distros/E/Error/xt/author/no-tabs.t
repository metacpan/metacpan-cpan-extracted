use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Error.pm',
    'lib/Error/Simple.pm',
    't/00-compile.t',
    't/01throw.t',
    't/02order.t',
    't/03throw-non-Error.t',
    't/04use-base-Error-Simple.t',
    't/05text-errors-with-file-handles.t',
    't/06customize-text-throw.t',
    't/07try-in-obj-destructor.t',
    't/08warndie.t',
    't/09dollar-at.t',
    't/10throw-in-catch.t',
    't/11rethrow.t',
    't/12wrong-error-var.t',
    't/13except-arg0.t',
    't/14Error-Simple-VERSION.t',
    't/lib/MyDie.pm'
);

notabs_ok($_) foreach @files;
done_testing;
