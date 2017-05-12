use inc::Module::Install;
name 'HTML-QRCode';
all_from 'lib/HTML/QRCode.pm';

requires 'Carp';
requires 'Text::QRCode';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
