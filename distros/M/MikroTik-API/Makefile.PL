use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name     'MikroTik-API';
all_from 'lib/MikroTik/API.pm';
author   q{Martin Gojowsky <martin@gojowsky.de>};
license  'mit';

perl_version 5.006;

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#MikroTik-API',
   license    => 'http://www.opensource.org/licenses/mit-license.php',
   repository => 'git://github.com/martin8883/MikroTik-API',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=MikroTik-API',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
	'Carp' => 0,
    'Digest::MD5' => 0,
    'IO::Socket::IP' => 0,
    'IO::Socket::SSL' => 0,
	'Moo' => 0,
	'MooX::Types::MooseLike::Base' => 0,
    'Time::Out' => 0,
	'Try::Tiny' => 0,
	'Type::Tiny' => 0,
    'namespace::autoclean' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
