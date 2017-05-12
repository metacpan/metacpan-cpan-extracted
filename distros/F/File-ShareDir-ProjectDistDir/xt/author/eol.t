use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/File/ShareDir/ProjectDistDir.pm',
    't/00-compile/lib_File_ShareDir_ProjectDistDir_pm.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/classic/01_devel.t',
    't/classic/02_installed_only.t',
    't/classic/03_installed_and_dev_different.t',
    't/classic/04_developing_installed.t',
    't/classic/05_devel_spec.t',
    't/classic/05_files/.devdir',
    't/classic/05_files/lib/Example_05.pm',
    't/classic/05_files/templates/file',
    't/classic/06_distname.t',
    't/deprecations/fatal_no_pathclass_installed.t',
    't/deprecations/warn_on_pathclass.t',
    't/lib/FakeFS.pm',
    't/strict/01_devel.t',
    't/strict/01_files/.devdir',
    't/strict/01_files/lib/Example_01.pm',
    't/strict/01_files/share/dist/Example_01/file',
    't/strict/02_installed_only.t',
    't/strict/03_installed_and_dev_different.t',
    't/strict/04_developing_installed.t',
    't/strict/05_devel_spec.t',
    't/strict/05_files/.devdir',
    't/strict/05_files/lib/Example_05.pm',
    't/strict/05_files/templates/dist/Example_05/file',
    't/strict/06_distname.t',
    't/strict/07_files/.devdir',
    't/strict/07_files/lib/Example_01.pm',
    't/strict/07_files/share/dist/Example_01/file',
    't/strict/07_gh15.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
