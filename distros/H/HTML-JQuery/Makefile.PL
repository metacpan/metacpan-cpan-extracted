use inc::Module::Install;

name     'HTML-JQuery';
all_from 'lib/HTML/JQuery.pm';
author   q{Brad Haywood <brad@geeksware.net>};
license  'perl';

requires 'Sub::Mage';
build_requires 'Test::More';

auto_install;

WriteAll;

