use inc::Module::Install;

name          'Egg-Release';
all_from      'lib/Egg/Release.pm';
version_from  'lib/Egg/Release.pm';
abstract_from 'lib/Egg/Release.pm';
author        'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license       'perl';

requires 'perl'                     => '5.8.1';
requires 'Carp'                     => '0';
requires 'CGI'                      => '3.33';
requires 'Class::Accessor'          => '0.31';
requires 'Class::C3'                => '0.19';
requires 'Class::Data::Inheritable' => '0.06';
requires 'Devel::StackTrace'        => '1.15';
requires 'Digest::MD5'              => '2.36';
requires 'Digest::SHA1'             => '2.11';
requires 'File::Path'               => '2.04';
requires 'File::Spec'               => '3.27';
requires 'File::Temp'               => '0.20';
requires 'File::Which'              => '0.05';
requires 'Getopt::Easy'             => '0.10';
requires 'HTML::Mason'              => '1.38';
requires 'HTML::Parser'             => '3.56';
requires 'HTML::Template'           => '2.90';
requires 'IO::Scalar'               => '2.11';
requires 'Jcode'                    => '2.06';
requires 'Module::Install'          => '0';
requires 'MIME::Base64'             => '3.07';
requires 'Tie::Hash::Indexed'       => '0.05';
requires 'Tie::RefHash'             => '1.38';
requires 'Time::HiRes'              => '0';
requires 'Time::Local'              => '1.18';
requires 'UNIVERSAL::require'       => '0.11';
requires 'URI'                      => '1.35';
requires 'YAML'                     => '0.66';
requires 'LWP'                      => '5.80';

requires 'FormValidator::Simple'    => '0.22';
requires 'HTML::FillInForm'         => '2.00';
requires 'HTML::Prototype'          => '1.48';
requires 'HTTP::BrowserDetect'      => '0.99';
requires 'ModPerl::VersionUtil'     => '0.03';
requires 'Module::Refresh'          => '0.13';
requires 'PersistentPerl'           => '2.21';

build_requires 'Test::More';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
