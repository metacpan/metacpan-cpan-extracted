use inc::Module::Install;
name 'Encode-Base58';
all_from 'lib/Encode/Base58.pm';

build_requires 'Test::More';
use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
