use inc::Module::Install;
name 'HTML-Trim';
all_from 'lib/HTML/Trim.pm';

requires $_ for (qw/Exporter::Lite HTML::Parser Unicode::EastAsianWidth/);

build_requires 'Test::More';
build_requires 'Test::Base';

use_test_base;
auto_include;
WriteAll;
