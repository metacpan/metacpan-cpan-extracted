use inc::Module::Install;

name          'HTML-Template-Ex';
all_from      'lib/HTML/Template/Ex.pm';
abstract_from 'lib/HTML/Template/Ex.pm';
version_from  'lib/HTML/Template/Ex.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'HTML::Template'    => 2.9;
requires 'HTML::Entities'    => 3.5;
requires 'Digest::MD5'       => 2.3;
requires 'Devel::StackTrace' => 1.1;

build_requires 'Test::More';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
