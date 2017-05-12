use inc::Module::Install;

name     'Geo-Address-Mail';
all_from 'lib/Geo/Address/Mail.pm';
author   q{Cory G Watson <gphat@cpan.org>};
license  'perl';

build_requires 'Test::More';
build_requires 'Test::Exception';

requires 'Moose';
requires 'MooseX::Clone';
requires 'MooseX::Storage';
requires 'MooseX::Types';
requires 'Regexp::Common';

WriteAll;

