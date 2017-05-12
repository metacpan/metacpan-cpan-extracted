use strict;
use warnings;
use inc::Module::Install;

name 'FeyX-Active';
all_from 'lib/FeyX/Active.pm';
license 'perl';

# prereqs
requires 'Fey';
requires 'Fey::DBIManager';

# things the tests need
build_requires 'DBI';
build_requires 'DBD::SQLite';
build_requires 'Test::More'      => '0.62';
build_requires 'Test::Exception' => '0.21';

tests('t/*.t');

WriteAll();

