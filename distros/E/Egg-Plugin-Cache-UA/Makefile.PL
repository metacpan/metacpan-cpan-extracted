use inc::Module::Install;

name          'Egg-Plugin-Cache-UA';
all_from      'lib/Egg/Plugin/Cache/UA.pm';
version_from  'lib/Egg/Plugin/Cache/UA.pm';
abstract_from 'lib/Egg/Plugin/Cache/UA.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'       => 3.06;
requires 'Egg::Plugin::LWP'   => 3.00;
requires 'Egg::Model::Cache'  => 0.01;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
