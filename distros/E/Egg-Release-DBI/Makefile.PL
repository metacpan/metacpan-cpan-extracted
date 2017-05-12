use inc::Module::Install;

name          'Egg-Release-DBI';
all_from      'lib/Egg/Release/DBI.pm';
version_from  'lib/Egg/Release/DBI.pm';
abstract_from 'lib/Egg/Release/DBI.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'       => '3.00';
requires 'DBI'                => '1.60';
requires 'Ima::DBI'           => '0.35';
requires 'UNIVERSAL::require' => '0.11';
requires 'SQL::Abstract'      => '1.22';
requires 'Time::Piece::MySQL' => '0.05';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
