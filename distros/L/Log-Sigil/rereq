use inc::Module::Install;
perl_version '5.008';

name 'Log-Sigil';
all_from 'lib/Log/Sigil.pm';
readme_from 'lib/Log/Sigil.pm';

requires "Class::Singleton";
requires "Class::Accessor";
requires "Readonly";

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::Output';
test_requires 'Test::More';

auto_set_repository;
auto_include;
WriteAll;
