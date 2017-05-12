use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MaxMind/DB/Reader/XS.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/MaxMind/DB/Reader-broken-databases.t',
    't/MaxMind/DB/Reader-decoder.t',
    't/MaxMind/DB/Reader-no-ipv4-search-tree.t',
    't/MaxMind/DB/Reader.t',
    't/MaxMind/DB/Reader/NoMoose.t',
    't/lib/Test/MaxMind/DB/Reader.pm',
    't/libmaxminddb-version.t',
    't/xs-only.t'
);

notabs_ok($_) foreach @files;
done_testing;
