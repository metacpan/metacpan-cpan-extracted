use inc::Module::Install;
name 'Lingua-JA-Yomi';
all_from 'lib/Lingua/JA/Yomi.pm';

requires 'Moose';
requires 'File::Slurp';

tests 't/*.t';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
