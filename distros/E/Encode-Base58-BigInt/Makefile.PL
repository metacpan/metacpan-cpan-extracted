use inc::Module::Install;
name 'Encode-Base58-BigInt';
all_from 'lib/Encode/Base58/BigInt.pm';

requires 'Exporter::Lite';
requires 'Math::BigInt';

build_requires 'Test::Most';

# Module::Install::AuthorTests
author_tests('xt');

# Module::Install::Repository
auto_set_repository;

# Module::Install::TestBase
use_test_base;

# Module::Install::ReadmeFromPod
readme_from 'lib/Encode/Base58/BigInt.pm';

auto_include;
WriteAll;
