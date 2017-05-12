use inc::Module::Install;
name 'GeoHash';
all_from 'lib/GeoHash.pm';
readme_from 'lib/GeoHash.pm';
readme_markdown_from 'lib/GeoHash.pm';
githubmeta;

requires 'parent';
requires 'Geo::Hash';
build_requires 'Test::More';
build_requires 'Test::Require';

tests 't/*.t';
author_tests 'xt';

auto_set_repository;
WriteAll;
