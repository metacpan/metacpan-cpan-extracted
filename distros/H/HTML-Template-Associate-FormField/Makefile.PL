use inc::Module::Install;

name          'HTML-Template-Associate-FormField';
all_from      'lib/HTML/Template/Associate/FormField.pm';
abstract_from 'lib/HTML/Template/Associate/FormField.pm';
version_from  'lib/HTML/Template/Associate/FormField.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

build_requires 'HTML::Template' => 2.9;

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
