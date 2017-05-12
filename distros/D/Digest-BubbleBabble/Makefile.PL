use inc::Module::Install;
name 'Digest-BubbleBabble';
all_from 'lib/Digest/BubbleBabble.pm';
readme_from 'lib/Digest/BubbleBabble.pm';

test_requires 'Test::More';

use_test_base;
auto_include_deps;
author_tests('xt');
auto_set_repository;
WriteAll;