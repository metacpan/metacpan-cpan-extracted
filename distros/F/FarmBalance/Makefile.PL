use inc::Module::Install;
name 'FarmBalance';
all_from 'lib/FarmBalance.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
