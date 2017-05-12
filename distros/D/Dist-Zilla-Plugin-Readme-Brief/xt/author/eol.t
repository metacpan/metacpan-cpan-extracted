use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Readme/Brief.pm',
    't/00-compile/lib_Dist_Zilla_Plugin_Readme_Brief_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/description_label.t',
    't/pod_file.t',
    't/podname.t',
    't/podnameci.t',
    't/source_file.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
