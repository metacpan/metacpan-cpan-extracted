use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Dist/Zilla/MintingProfile/Author/KENTNL.pm',
    'lib/Dist/Zilla/Plugin/Author/KENTNL/DistINI.pm',
    'lib/Dist/Zilla/Plugin/Author/KENTNL/MinimumPerl.pm',
    'lib/Dist/Zilla/PluginBundle/Author/KENTNL.pm',
    't/00-compile/lib_Dist_Zilla_MintingProfile_Author_KENTNL_pm.t',
    't/00-compile/lib_Dist_Zilla_PluginBundle_Author_KENTNL_pm.t',
    't/00-compile/lib_Dist_Zilla_Plugin_Author_KENTNL_DistINI_pm.t',
    't/00-compile/lib_Dist_Zilla_Plugin_Author_KENTNL_MinimumPerl_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-Minter.t',
    't/02-Minter-Moo-Role.t',
    't/02-Minter-Moo.t',
    't/02-Minter-Moose-Role.t',
    't/lib/tshare.pm'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
