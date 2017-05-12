use inc::Module::Install;
name 'HTML-AutoPagerize';
all_from 'lib/HTML/AutoPagerize.pm';

requires 'URI';
requires 'HTML::TreeBuilder::XPath';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
