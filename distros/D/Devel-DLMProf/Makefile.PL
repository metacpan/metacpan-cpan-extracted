use inc::Module::Install;
name 'Devel-DLMProf';
all_from 'lib/Devel/DLMProf.pm';

requires 'Path::Class';
requires 'Linux::Smaps';
requires 'mod_perl2';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
