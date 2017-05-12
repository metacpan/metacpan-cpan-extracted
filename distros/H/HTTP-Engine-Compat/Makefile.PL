use inc::Module::Install;
name 'HTTP-Engine-Compat';
all_from 'lib/HTTP/Engine/Compat.pm';

requires 'HTTP::Engine' => '0.0.15';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';
test_requires 'Test::More';
test_requires 'YAML';
author_tests 'xt';
use_test_base;
auto_include;
WriteAll;
