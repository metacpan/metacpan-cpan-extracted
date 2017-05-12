use inc::Module::Install;
name 'Geo-Coordinates-Converter-Format-Geohash';
all_from 'lib/Geo/Coordinates/Converter/Format/Geohash.pm';
readme_from 'lib/Geo/Coordinates/Converter/Format/Geohash.pm';
readme_markdown_from 'lib/Geo/Coordinates/Converter/Format/Geohash.pm';
githubmeta;

requires 'parent';
requires 'Class::Accessor::Lite'       => '0.05';
requires 'Geo::Coordinates::Converter' => '0.07';
requires 'Geohash'                     => '0.02';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::Base';
build_requires 'Test::More';
build_requires 'YAML';

auto_set_repository;
WriteAll;
