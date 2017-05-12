use inc::Module::Install;
name 'HTML-StickyQuery';
all_from 'lib/HTML/StickyQuery.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

requires 'parent';
requires 'HTML::Parser' => '3.00';
requires 'URI';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
