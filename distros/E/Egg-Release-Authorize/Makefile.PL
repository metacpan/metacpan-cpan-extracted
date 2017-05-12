use inc::Module::Install;

name          'Egg-Release-Authorize';
all_from      'lib/Egg/Release/Authorize.pm';
version_from  'lib/Egg/Release/Authorize.pm';
abstract_from 'lib/Egg/Release/Authorize.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'            => '3.14';
requires 'Egg::Plugin::SessionKit' => '3.02';
requires 'Egg::Release::DBI'       => '0.02';
requires 'Egg::Release::DBIC'      => '0.02';
requires 'Digest::MD5'             => '2.36';
requires 'Digest::SHA1'            => '2.11';
requires 'Crypt::CBC'              => '2.24';
requires 'Crypt::Blowfish'         => '2.10';
requires 'Crypt::DES'              => '2.05';
requires 'Crypt::Camellia'         => '2.01';
requires 'Cache::Cache'            => '1.05';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
