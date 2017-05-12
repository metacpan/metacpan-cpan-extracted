use inc::Module::Install;
name 'File-Stat-Trigger';
all_from 'lib/File/Stat/Trigger.pm';

requires 'Moose';
requires 'Moose::Util::TypeConstraints';
requires 'File::Stat::OO';
requires 'Class::Trigger';
requires 'DateTime';
requires 'DateTime::TimeZone';
requires 'DateTime::Format::DateParse';
requires 'Module::Install::AuthorTests';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
