use strict;
use warnings;
use inc::Module::Install;
use 5.008005;

name 'Ima-DBI-Contextual';
perl_version '5.008001';
license 'perl';
all_from 'lib/Ima/DBI/Contextual.pm';

test_requires 'Test::More'  => '0';
test_requires 'DBD::SQLite' => '0';

requires      'DBI'         => '1.614';
requires      'Carp'        => '0';
requires      'Digest::MD5' => '0';

tests_recursive();
WriteAll();

