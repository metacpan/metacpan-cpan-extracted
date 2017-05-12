use strict;
use warnings;
use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;

all_from 'lib/LLEval.pm';

install_script 'lleval';

requires 'Furl'         => 0.07;
requires 'JSON';
requires 'URI::Escape';

requires 'Mouse'                     => 0.70;
requires 'MouseX::StrictConstructor' => 0.02;
requires 'MouseX::Getopt';

test_requires 'Test::More' => '0.88';

auto_set_repository;

tests_recursive;
author_tests 'xt';


clean_files qw(
    LLEval-*
    *.stackdump
    cover_db *.gcov *.gcda *.gcno
    nytprof
    *.out
);

WriteAll(check_nmake => 0);
