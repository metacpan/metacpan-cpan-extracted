use inc::Module::Install;

name          'Egg-Release-Mail';
all_from      'lib/Egg/Release/Mail.pm';
version_from  'lib/Egg/Release/Mail.pm';
abstract_from 'lib/Egg/Release/Mail.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'           => '3.03';
requires 'Egg::Model::FsaveDate'  => '0.01';
requires 'Egg::Plugin::Net::Scan' => '3.00';
requires 'MIME::Entity'           => '5.42';
requires 'Digest::SHA1'           => '2.11';
requires 'Jcode'                  => '2.06';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
