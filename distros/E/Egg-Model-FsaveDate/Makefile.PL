use inc::Module::Install;

name          'Egg-Model-FsaveDate';
all_from      'lib/Egg/Model/FsaveDate.pm';
version_from  'lib/Egg/Model/FsaveDate.pm';
abstract_from 'lib/Egg/Model/FsaveDate.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'Egg::Release'   => '3.03';
requires 'Digest::SHA1'   => '2.11';
requires 'File::Path'     => '2.04';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
