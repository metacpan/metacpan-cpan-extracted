use inc::Module::Install;

name     'LWP-Curl';
all_from 'lib/LWP/Curl.pm';
author   'Lindolfo Rodrigues de Oliveira Neto <lorn@cpan.org>';

test_requires 'Test::More';
test_requires 'Test::Exception';
build_requires 'URI::file';
requires 'Net::Curl::Easy';
requires 'Carp';
requires 'URI::Escape';
requires 'Data::Dumper';
auto_install;

WriteAll;

