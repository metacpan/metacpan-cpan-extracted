use inc::Module::Install;
name 'HTTP-MobileAgent-Plugin-SmartPhone';
all_from 'lib/HTTP/MobileAgent/Plugin/SmartPhone.pm';

requires 'HTTP::MobileAgent';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Base';
auto_set_repository;
auto_include;
WriteAll;
