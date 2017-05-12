use inc::Module::Install;
name 'Egg-Plugin-LWP';
all_from 'lib/Egg/Plugin/LWP.pm';
version_from 'lib/Egg/Plugin/LWP.pm';

requires 'Egg::Release' => 3.00;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
