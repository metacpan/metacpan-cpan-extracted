use inc::Module::Install;
name 'HTML5-Manifest';
all_from 'lib/HTML5/Manifest.pm';
readme_from 'lib/HTML5/Manifest.pm';
readme_markdown_from 'lib/HTML5/Manifest.pm';
githubmeta;

requires 'Digest::MD5';
requires 'File::Spec';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
