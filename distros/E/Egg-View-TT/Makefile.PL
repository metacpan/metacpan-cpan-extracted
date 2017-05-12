use inc::Module::Install;

name         'Egg-View-TT';
all_from     'lib/Egg/View/TT.pm';
version_from 'lib/Egg/View/TT.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release' => '3.00';
requires 'Template'     => '2.19';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_install;
WriteAll;
