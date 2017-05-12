use inc::Module::Install;
name 'HTTP-Router';
all_from 'lib/HTTP/Router.pm';

readme_from 'lib/HTTP/Router.pm';
readme_pod_from 'lib/HTTP/Router.pm';
auto_set_repository;

# Core
requires 'Class::Accessor::Fast';
requires 'Hash::AsObject';
requires 'List::MoreUtils';
requires 'Scalar::Util' => '1.14';
requires 'URI::Template::Restrict' => '0.05';

# Declare
requires 'Carp';
requires 'Storable';
requires 'Devel::Caller::Perl';
requires 'String::CamelCase';
requires 'Lingua::EN::Inflect::Number';

# Debug
requires 'Text::SimpleTable';

tests 't/*.t t/*/*.t';
test_requires 'Test::More';
test_requires 'Test::UseAllModules';
test_requires 'Test::MockObject';
test_requires 'Test::Deep';
use_test_base;

author_tests 'xt';
author_requires 'Test::Pod';
author_requires 'Test::Pod::Coverage';
author_requires 'Test::Spelling';
author_requires 'ShipIt';
author_requires 'ShipIt::Step::Manifest';
author_requires 'ShipIt::Step::DistClean';
author_requires 'ShipIt::Step::Twitter';

auto_include_deps;
WriteAll;
