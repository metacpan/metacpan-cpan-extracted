use inc::Module::Install;

name         'Egg-Plugin-Net-Scan';
all_from     'lib/Egg/Plugin/Net/Scan.pm';
version_from 'lib/Egg/Plugin/Net/Scan.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release' => 2.00;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
