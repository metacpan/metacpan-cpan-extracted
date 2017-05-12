use inc::Module::Install;
name 'Geo-Google-StaticMaps-Navigation';
all_from 'lib/Geo/Google/StaticMaps/Navigation.pm';

# requires '';
requires 'Geo::Google::StaticMaps';
requires 'Geo::Mercator';
requires 'Carp';
requires 'URI';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More' => '0.88';
auto_include;
auto_set_repository;
WriteAll;
