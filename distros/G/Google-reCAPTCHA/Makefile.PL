use 5.006;
use strict;
use warnings;
use inc::Module::Install;

name     'Google-reCAPTCHA';
all_from 'lib/Google/reCAPTCHA.pm';
author   q{Thomas Corkran <thomascorkran@gmail.com>};
license  'perl';

perl_version 5.006;

tests_recursive('t');

resources (
   license    => 'http://dev.perl.org/licenses/',
   repository => 'https://bitbucket.org/tcorkran/google-recaptcha',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Google-reCAPTCHA',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More'       => 0,
   'Test::Most'       => 0,
   'Test::MockModule' => 0.11,
);

requires (
   'JSON'             => 2.90,
   'LWP::UserAgent'   => 6.15,
   'Params::Validate' => 1.21,
);

install_as_cpan;
auto_install;
WriteAll;
