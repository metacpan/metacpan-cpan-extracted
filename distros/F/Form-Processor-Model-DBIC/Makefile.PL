use strict;
use warnings;
use inc::Module::Install;

name 'Form-Processor-Model-DBIC';
all_from 'lib/Form/Processor/Model/DBIC.pm';
license 'perl';

# prereqs
requires 'Form::Processor';
requires 'DBIx::Class';
requires 'Carp';

# things the tests need
build_requires 'Test::More'      => '0.89';

tests_recursive();

auto_install();

WriteAll();

