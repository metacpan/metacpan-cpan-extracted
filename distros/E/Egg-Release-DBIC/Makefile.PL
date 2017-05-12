use inc::Module::Install;

name          'Egg-Release-DBIC';
all_from      'lib/Egg/Release/DBIC.pm';
version_from  'lib/Egg/Release/DBIC.pm';
abstract_from 'lib/Egg/Release/DBIC.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'                => '3.00';
requires 'DBIx::Class'                 => '0.08009';
requires 'DBIx::Class::Schema::Loader' => '0.03';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
