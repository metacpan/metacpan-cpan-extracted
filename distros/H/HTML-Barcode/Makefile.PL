use strict;
use warnings;
use inc::Module::Install;

name     'HTML-Barcode';
license  'perl';
all_from 'lib/HTML/Barcode.pm';

requires 'Moo';


test_requires 'Test::More';
tests 't/*.t';
author_tests 'xt';

auto_set_repository;
auto_install;
WriteAll;
