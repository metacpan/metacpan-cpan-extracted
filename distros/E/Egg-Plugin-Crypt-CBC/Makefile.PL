use inc::Module::Install;

name          'Egg-Plugin-Crypt-CBC';
all_from      'lib/Egg/Plugin/Crypt/CBC.pm';
version_from  'lib/Egg/Plugin/Crypt/CBC.pm';
abstract_from 'lib/Egg/Plugin/Crypt/CBC.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'    => 2.00;
requires 'Crypt::CBC'      => 2.22;
requires 'Crypt::Blowfish' => 2.10;
requires 'Crypt::DES'      => 2.05;
requires 'Crypt::Camellia' => 2.01;
requires 'Crypt::Rabbit'   => 1.00;
requires 'Crypt::Twofish2' => 1.01;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
