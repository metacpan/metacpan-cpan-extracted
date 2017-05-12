use inc::Module::Install;
name 'HTML-RelExtor';
all_from 'lib/HTML/RelExtor.pm';
requires 'HTML::Parser', 3.0;
build_requires 'Test::More';
use_test_base;
auto_set_repository;
auto_include;
WriteAll;
