use inc::Module::Install;

name     'Geo-Address-Mail-UK';
all_from 'lib/Geo/Address/Mail/UK.pm';
author   q{Andrew Nelson <anelson@cpan.org>};
license  'perl';

build_requires 'Test::More';
build_requires 'Test::Exception';

requires 'Geo::Address::Mail';

WriteAll;

