use inc::Module::Install;
name 'Image-LibRaw';
all_from 'lib/Image/LibRaw.pm';
license 'perl';

use_ppport 3.19;

can_cc or die "This module requires a C compiler";
checklibs lib => 'raw', header => 'libraw/libraw.h';

libs '-lraw -lstdc++';
# add -lgomp if needed...

clean_files qw{
    *.stackdump
    *.gcov *.gcda *.gcno
    *.out
    nytprof
    cover_db
};

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
build_requires 'Test::Requires';
build_requires 'Devel::CheckLib';

auto_set_repository;
WriteAll;
