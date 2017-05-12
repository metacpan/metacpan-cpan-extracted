use inc::Module::Install;
name 'Finance-TW-TSEQuote';
all_from 'lib/Finance/TW/TSEQuote.pm';
readme_from 'lib/Finance/TW/TSEQuote.pm';
build_requires 'Test::More' => 0.88;
extra_tests;
auto_set_repository;

install_script glob('scripts/*');

requires 'LWP::Simple';
requires 'URI::Escape';
requires 'App::Cache';
requires 'HTML::TableExtract';

WriteAll;
