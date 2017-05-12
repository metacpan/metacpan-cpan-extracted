use inc::Module::Install;
name 'IO-File-WithPath';
all_from 'lib/IO/File/WithPath.pm';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
author_tests 'xt';
auto_include;
WriteAll;
