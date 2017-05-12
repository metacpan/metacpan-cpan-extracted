use inc::Module::Install;
name 'JSONRPC-Transport-TCP';
all_from 'lib/JSONRPC/Transport/TCP.pm';

perl_version '5.008001';

requires 'Class::Accessor::Fast';
requires 'IO::Select';
requires 'IO::Socket::INET';
requires 'IO::Socket::UNIX';
requires 'Carp';
requires 'JSON';

recommends 'JSON::XS';

test_requires 'Test::More';
test_requires 'Test::TCP' => '0.08';

use_test_base;
author_tests 'xt';

auto_include;
auto_set_repository;

WriteAll;
