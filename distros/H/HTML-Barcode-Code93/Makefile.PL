use inc::Module::Install;
name 'HTML-Barcode-Code93';
license 'perl';
all_from 'lib/HTML/Barcode/Code93.pm';

requires 'HTML::Barcode'   => '0.13';
requires 'Moo';
requires 'Barcode::Code93' => '0.02';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_install;
WriteAll;
