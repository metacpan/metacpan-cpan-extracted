use inc::Module::Install;
name 'Feed-Find';
all_from 'lib/Feed/Find.pm';
readme_from 'lib/Feed/Find.pm';

requires 'Class::ErrorHandler';
requires 'LWP';
requires 'HTML::Parser';
requires 'URI';

test_requires 'Test::More';

use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;
