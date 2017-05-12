use inc::Module::Install;

name       'Devel-PatchPerl-Plugin-Legacy';
all_from   'lib/Devel/PatchPerl/Plugin/Legacy.pm';
license    'perl';
repository 'https://github.com/hirose31/devel-patchperl-plugin-legacy';

requires 'Devel::PatchPerl';

test_requires 'Test::More' => 0.88;

tests_recursive;
author_tests 'xt';

use_test_base;
WriteAll;
