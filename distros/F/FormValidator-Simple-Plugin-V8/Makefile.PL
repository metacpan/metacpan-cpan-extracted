use inc::Module::Install;
name 'FormValidator-Simple-Plugin-V8';
all_from 'lib/FormValidator/Simple/Plugin/V8.pm';

requires 'JavaScript::V8';
requires 'FormValidator::Simple';

build_requires 'Test::More';

# Module::Install::AuthorTests
author_tests('xt');

# Module::Install::Repository
auto_set_repository;

# Module::Install::ReadmeFromPod
readme_from 'lib/FormValidator/Simple/Plugin/V8.pm';

auto_include;
WriteAll;
