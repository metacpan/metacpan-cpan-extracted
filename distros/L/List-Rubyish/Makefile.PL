use inc::Module::Install;
use 5.008001;
name 'List-Rubyish';
all_from 'lib/List/Rubyish.pm';

requires 'Carp';
requires 'List::Util';
requires 'List::MoreUtils';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::Class';
build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
