use inc::Module::Install;

name          'Egg-Model-Cache';
all_from      'lib/Egg/Model/Cache.pm';
version_from  'lib/Egg/Model/Cache.pm';
abstract_from 'lib/Egg/Model/Cache.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'  => '3.03';
requires 'Cache::Cache'  => '1.05';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
