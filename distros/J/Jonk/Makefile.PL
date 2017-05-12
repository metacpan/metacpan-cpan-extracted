use inc::Module::Install;
name 'Jonk';
all_from 'lib/Jonk.pm';

requires 'DBI';
requires 'Try::Tiny';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => '0.94';
test_requires 'Test::mysqld'     if $Module::Install::AUTHOR;
test_requires 'Test::postgresql' if $Module::Install::AUTHOR;

auto_set_repository;

WriteAll;
