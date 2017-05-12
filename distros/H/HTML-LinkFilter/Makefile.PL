use inc::Module::Install;
name 'HTML-LinkFilter';
all_from 'lib/HTML/LinkFilter.pm';

requires "URI";
requires "HTML::Parser";

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
