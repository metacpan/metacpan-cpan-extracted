use inc::Module::Install;

name         'Egg-Plugin-Authen-Captcha';
all_from     'lib/Egg/Plugin/Authen/Captcha.pm';
version_from 'lib/Egg/Plugin/Authen/Captcha.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release'    => 3.03;
requires 'Authen::Captcha' => 1.02;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
