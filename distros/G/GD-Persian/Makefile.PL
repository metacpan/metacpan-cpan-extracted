use inc::Module::Install;

name     'GD-Persian';
all_from 'lib/GD/Persian.pm';
author   q{Milad Rastian <milad@cpan.org>};
license  'perl';

homepage 'https://github.com/slashmili/perl-gd-persian';
repository 'git://github.com/slashmili/perl-gd-persian.git';
bugtracker 'https://github.com/slashmili/perl-gd-persian/issues';

requires 'GD';

build_requires 'Test::More' => 0.96;

auto_install;

WriteAll;
