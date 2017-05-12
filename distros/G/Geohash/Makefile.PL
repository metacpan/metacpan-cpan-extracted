use inc::Module::Install;
name 'Geohash';
all_from 'lib/Geohash.pm';
readme_from 'lib/Geohash.pm';
readme_markdown_from 'lib/Geohash.pm';
githubmeta;

requires 'parent';
requires 'Geo::Hash';
build_requires 'Test::More';

tests 't/*.t';
author_tests 'xt';

auto_set_repository;
WriteAll;
