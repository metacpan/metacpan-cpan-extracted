use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/JSON/Meth.pm',
    't/00-compile.t',
    't/01-meth.t',
    't/02-overloads.t',
    't/03-objects.t',
    't/04-json-var-export.t',
    't/05-undef.t'
);

notabs_ok($_) foreach @files;
done_testing;
