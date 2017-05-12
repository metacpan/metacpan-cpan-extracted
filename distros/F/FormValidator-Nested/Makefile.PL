use inc::Module::Install;
name 'FormValidator-Nested';
all_from 'lib/FormValidator/Nested.pm';

# requires '';
requires 'Any::Moose';
requires_any_moose 'X::Types::Path::Class';
requires_any_moose 'X::AttributeHelpers';
requires 'namespace::clean';
requires 'YAML::Syck';
requires 'Path::Class';
requires 'UNIVERSAL::require';
requires 'Class::Param';
requires 'Lingua::JA::Regular::Unicode';
requires 'List::MoreUtils';
requires 'Hash::Merge';
requires 'DateTime';
requires 'DateTime::TimeZone';


tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Test::LoadAllModules';
test_requires 'Data::Visitor::Callback';
test_requires 'DBIx::Class';
test_requires 'DBIx::Class::Schema';
test_requires 'Test::Fixture::DBIC::Schema';
test_requires 'DBICx::TestDatabase';
test_requires 'SQL::Translator' => '0.11002';
author_tests 'xt';
use_test_base;
auto_include;
WriteAll;
