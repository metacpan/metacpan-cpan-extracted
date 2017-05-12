use inc::Module::Install;

name         'Egg-Release-JSON';
all_from     'lib/Egg/Release/JSON.pm';
version_from 'lib/Egg/Release/JSON.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release'     => 2.20;
requires 'Egg::Plugin::LWP' => 2.01;
requires 'JSON'             => 1.14;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
