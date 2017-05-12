sub readme_from {}; sub auto_include_deps {}; sub author_tests {}; sub auto_set_repository {};
use strict;
use inc::Module::Install;

name 'IO-Digest';
all_from 'lib/IO/Digest.pm';

requires 'PerlIO::via::dynamic'   => '0.10';
requires 'Digest'		 => '0.0';

auto_set_repository;
WriteAll;
