use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Util/ExpandINI.pm',
    'lib/Dist/Zilla/Util/ExpandINI/Reader.pm',
    'lib/Dist/Zilla/Util/ExpandINI/Writer.pm',
    't/00-compile/lib_Dist_Zilla_Util_ExpandINI_Reader_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_ExpandINI_Writer_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_ExpandINI_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/comments/all.t',
    't/comments/authordeps.t',
    't/comments/basic.t',
    't/comments/none.t',
    't/expand_classic.t',
    't/expand_classic_fitered.t',
    't/expand_classic_simple.t',
    't/simple_io.t',
    't/simple_io_bundle.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
