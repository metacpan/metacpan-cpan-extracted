use 5.006;
use strict;
use warnings;
use inc::Module::Install;

name     'Lingua-Numending';
all_from 'lib/Lingua/Numending.pm';
author   q{Dariya Kirillova <kirillova@cpan.org>};
license  'artistic2';

perl_version 5.006;

tests_recursive('t');

resources (
   #homepage   => 'http://yourwebsitehere.com',
   #IRC        => 'irc://irc.perl.org/#Lingua-Numending',
   license    => 'http://www.perlfoundation.org/artistic_license_2_0',
   #repository => 'git://github.com/Dariya Kirillova/Lingua-Numending.git',
   #repository => 'https://bitbucket.org/Dariya Kirillova/Lingua-Numending',
   bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Numending',
);

configure_requires (
   'Module::Install' => 0,
);

build_requires (
   'Test::More' => 0,
);

requires (
   #'ABC'              => 1.6,
   #'Foo::Bar::Module' => 5.0401,
);

install_as_cpan;
auto_install;
WriteAll;
