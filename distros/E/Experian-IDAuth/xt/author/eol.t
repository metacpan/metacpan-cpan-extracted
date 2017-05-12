use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Experian/IDAuth.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/decision.t',
    't/get_result_check_id.t',
    't/get_result_prove_id.t',
    't/rc/.perlcriticrc',
    't/rc/.perltidyrc',
    't/xml_as_hash.t',
    't/xml_report.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
