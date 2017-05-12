use inc::Module::Install;

name     'Geo-Address-Mail-Standardizer-USPS';
all_from 'lib/Geo/Address/Mail/Standardizer/USPS.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Moose' => '0.90'; # Uses Native, so depend on .90
requires 'Geo::Address::Mail::Standardizer';

WriteAll;

