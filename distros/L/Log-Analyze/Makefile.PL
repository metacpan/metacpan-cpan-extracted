use inc::Module::Install;
name 'Log-Analyze';
all_from 'lib/Log/Analyze.pm';
requires 'Carp';
build_requires 'Test::More';
build_requires 'File::Spec';
use_test_base;
auto_include;
WriteAll;
