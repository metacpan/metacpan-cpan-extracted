use inc::Module::Install;
name 'Mac-MissileLauncher';
all_from 'lib/Mac/MissileLauncher.pm';

requires $_ for (qw/ Carp Inline::C /);

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
