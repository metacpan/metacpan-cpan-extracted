use inc::Module::Install;

name 'HTTP-Response-Maker';
all_from 'lib/HTTP/Response/Maker.pm';

requires 'HTTP::Status';
requires 'Class::Load';
requires 'Sub::Name';
requires 'parent';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
test_requires 'Test::Requires';

auto_set_repository;
auto_include;

WriteAll;
