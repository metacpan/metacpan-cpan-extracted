use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/Gentoo/Overlay.pm',
    'lib/Gentoo/Overlay/Category.pm',
    'lib/Gentoo/Overlay/Ebuild.pm',
    'lib/Gentoo/Overlay/Exceptions.pm',
    'lib/Gentoo/Overlay/Package.pm',
    'lib/Gentoo/Overlay/Types.pm',
    't/00-compile/lib_Gentoo_Overlay_Category_pm.t',
    't/00-compile/lib_Gentoo_Overlay_Ebuild_pm.t',
    't/00-compile/lib_Gentoo_Overlay_Exceptions_pm.t',
    't/00-compile/lib_Gentoo_Overlay_Package_pm.t',
    't/00-compile/lib_Gentoo_Overlay_Types_pm.t',
    't/00-compile/lib_Gentoo_Overlay_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/ebuild.t',
    't/iterate.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
