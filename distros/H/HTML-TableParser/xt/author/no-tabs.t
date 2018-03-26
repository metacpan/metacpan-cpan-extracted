use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/HTML/TableParser.pm',
    'lib/HTML/TableParser/Table.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/class-01.t',
    't/class.t',
    't/common.pl',
    't/contents.t',
    't/counts.pl',
    't/end_table.t',
    't/funcs.t',
    't/methods.t',
    't/req_order.t'
);

notabs_ok($_) foreach @files;
done_testing;
