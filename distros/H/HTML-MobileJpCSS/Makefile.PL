use inc::Module::Install;
name 'HTML-MobileJpCSS';
all_from 'lib/HTML/MobileJpCSS.pm';

requires 'Carp';
requires 'File::Spec';
requires 'CSS::Tiny';
requires 'YAML::Syck';
requires 'HTTP::MobileAgent';

build_requires 'Test::More';
use_test_base;
auto_include;
auto_install;
WriteAll;
