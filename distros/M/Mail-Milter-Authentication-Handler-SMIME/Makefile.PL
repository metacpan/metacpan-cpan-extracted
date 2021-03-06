use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'Mail-Milter-Authentication-Handler-SMIME';
all_from 'lib/Mail/Milter/Authentication/Handler/SMIME.pm';
author   q{Marc Bradshaw <marc@marcbradshaw.net>};
license  'perl';

perl_version 5.006;

tests_recursive('t');

resources (
   #homepage   => '',
   #IRC        => 'irc://irc.perl.org/#Mail-Milter-Authentication',
   license    => 'http://dev.perl.org/licenses/',
   repository => 'https://github.com/fastmail/authentication_milter_smime/',
   bugtracker => 'https://github.com/fastmail/authentication_milter_smime/issues/',
);

configure_requires (
   'Module::Install' => 0,
   'version'         => 0,
);

build_requires (
    'Test::More'           => 0,
    'Test::File::Contents' => 0,
    'Test::Perl::Critic'   => 0,
    'Test::CheckManifest'  => 0,
    'Test::Pod::Coverage'  => 0,
    'Test::Pod'            => 0,
    'Test::MockModule'     => 0,
);

requires (
    'Convert::X509' => 0,
    'Crypt::SMIME'  => 0.15,
    'Email::MIME'   => 0,
    'Mail::Milter::Authentication' => '1.1.7',
);

install_as_cpan;
auto_install;
WriteAll;
