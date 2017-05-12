use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Util/EmulatePhase.pm',
    'lib/Dist/Zilla/Util/EmulatePhase/PrereqCollector.pm',
    't/00-compile/lib_Dist_Zilla_Util_EmulatePhase_PrereqCollector_pm.t',
    't/00-compile/lib_Dist_Zilla_Util_EmulatePhase_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-getprereqs.t',
    't/02-makemaker-sharedir.t',
    't/03-dedup.t',
    't/04-expand-modname.t',
    't/05-get-plugins.t',
    't/06-get-metadata.t',
    't/07-errorconditions.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
