use strict;
use warnings;
use inc::Module::Install;

all_from 'lib/File/Spec/Memoized.pm';

requires 'File::Spec' => 3.2701;

test_requires 'Test::More' => 0.88; # done_testing()

tests 't/*.t', 't/*/*.t';
author_tests 'xt';

auto_set_repository() if -d '.git';

clean_files qw(
    File-Spec-Memoized-* *.stackdump
    cover_db
    nytprof
    *.out
);

WriteAll check_nmake => 0;
