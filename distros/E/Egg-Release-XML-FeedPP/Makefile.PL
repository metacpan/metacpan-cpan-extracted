use inc::Module::Install;

name         'Egg-Release-XML-FeedPP';
all_from     'lib/Egg/Release/XML/FeedPP.pm';
version_from 'lib/Egg/Release/XML/FeedPP.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release'       => 2.20;
requires 'Egg::Plugin::Cache' => 2.01;
requires 'XML::FeedPP'        => 0.22;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
