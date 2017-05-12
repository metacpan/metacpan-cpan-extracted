use inc::Module::Install;

name          'Egg-Plugin-SessionKit';
all_from      'lib/Egg/Plugin/SessionKit.pm';
version_from  'lib/Egg/Plugin/SessionKit.pm';
abstract_from 'lib/Egg/Plugin/SessionKit.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'       => '3.00';
requires 'Egg::Release::DBI'  => '0.01';
requires 'Egg::Release::DBIC' => '0.01';
requires 'Cache::Cache'       => '1.05';
requires 'Data::UUID'         => '1.14';
requires 'Storable'           => '2.18';
requires 'Convert::UU'        => '0.05';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
