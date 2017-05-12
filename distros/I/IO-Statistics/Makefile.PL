sub readme_from {}; sub auto_include_deps {}; sub author_tests {}; sub auto_set_repository {};
use strict;
use inc::Module::Install;

name 'IO-Statistics';
all_from 'lib/IO/Statistics.pm';

requires 'PerlIO::via::dynamic'   => '0.10';

auto_set_repository;
WriteAll;
