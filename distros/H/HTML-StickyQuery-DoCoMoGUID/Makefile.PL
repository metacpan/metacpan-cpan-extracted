use inc::Module::Install;
name 'HTML-StickyQuery-DoCoMoGUID';
all_from 'lib/HTML/StickyQuery/DoCoMoGUID.pm';
readme_from 'lib/HTML/StickyQuery/DoCoMoGUID.pm';

requires 'HTML::StickyQuery' => '0.13';

build_requires 'Test::More';
use_test_base;

tests 't/*.t';
author_tests 'xt';

auto_include;
githubmeta;
auto_set_repository;
WriteAll;
