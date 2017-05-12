use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/Test/Compile/PerFile.pm',
    't/00-compile/lib_Dist_Zilla_Plugin_Test_Compile_PerFile_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/attr_file.t',
    't/attr_finder.t',
    't/attr_path_translator_mimic_source.t',
    't/attr_skip.t',
    't/attr_xtmode.t',
    't/basic.t',
    't/failtest.t',
    't/oktest.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
