use strict;
use warnings;
use inc::Module::Install;

name     'FormValidator-Simple-Plugin-DBIC-Schema-Unique';
all_from 'lib/FormValidator/Simple/Plugin/DBIC/Schema/Unique.pm';

requires 'FormValidator::Simple';
requires 'DBIx::Class';
requires 'Scalar::Util';

build_requires 'Test::Declare';

use_test_base;
auto_install;
WriteAll;

