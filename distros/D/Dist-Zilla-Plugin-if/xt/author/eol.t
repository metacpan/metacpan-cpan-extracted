use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/Plugin/if.pm',
    'lib/Dist/Zilla/Plugin/if/not.pm',
    't/00-compile/lib_Dist_Zilla_Plugin_if_not_pm.t',
    't/00-compile/lib_Dist_Zilla_Plugin_if_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/if/env-disable.t',
    't/if/no-plugin.t',
    't/if/pass-args.t',
    't/if/plugin-doublelevel.t',
    't/if/plugin-only-2.t',
    't/if/plugin-only.t',
    't/ifnot/env-disable.t',
    't/ifnot/no-plugin.t',
    't/ifnot/pass-args.t',
    't/ifnot/plugin-doublelevel.t',
    't/ifnot/plugin-only-2.t',
    't/ifnot/plugin-only.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
