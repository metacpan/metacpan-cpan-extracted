use inc::Module::Install;

name     'Email-Sample';
all_from 'lib/Email/Sample.pm';
author   'Cornelius <cornelius.howl@gmail.com>';
license  'MIT';

build_requires 'Test::More';
requires 'Data::Random';

auto_install;

WriteAll;

