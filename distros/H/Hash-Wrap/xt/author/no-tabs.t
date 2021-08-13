use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Hash/Wrap.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/api.t',
    't/as_return.t',
    't/as_scalar_ref.t',
    't/basic.t',
    't/basic.t.orig',
    't/croak.t',
    't/defined.t',
    't/exists.t',
    't/immutable.t',
    't/import.t',
    't/lockkeys.t',
    't/lvalue.t',
    't/lvalue_undef.t',
    't/methods.t',
    't/predicate.t',
    't/recurse.t',
    't/subclass.t',
    't/undef.t'
);

notabs_ok($_) foreach @files;
done_testing;
