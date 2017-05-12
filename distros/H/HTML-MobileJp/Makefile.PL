use inc::Module::Install;
name 'HTML-MobileJp';
all_from 'lib/HTML/MobileJp.pm';

requires 'URI::Escape'      => 3.29;
requires 'HTML::Entities'   => 1.35;
requires 'Params::Validate' => 0.89;

test_requires 'Test::Base';
test_requires 'Test::More' => 0.98;
test_requires 'YAML';
author_tests('xt');
WriteAll;
