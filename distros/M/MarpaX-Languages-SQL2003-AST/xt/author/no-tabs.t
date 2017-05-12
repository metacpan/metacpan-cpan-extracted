use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/sql2003ast',
    'lib/MarpaX/Languages/SQL2003/AST.pm',
    'lib/MarpaX/Languages/SQL2003/AST/Actions.pm',
    'lib/MarpaX/Languages/SQL2003/AST/Actions/Blessed.pm',
    'lib/MarpaX/Languages/SQL2003/AST/Actions/XML.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all_tests.t'
);

notabs_ok($_) foreach @files;
done_testing;
