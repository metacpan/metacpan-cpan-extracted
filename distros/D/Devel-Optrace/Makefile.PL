use strict;
use warnings;
use inc::Module::Install;

name 'Devel-Optrace';
all_from 'lib/Devel/Optrace.pm';

build_requires 'ExtUtils::ParseXS';

test_requires 'Test::More' => 0.62;

tests 't/*.t';
author_tests 'xt';

WriteMakefile(
	OBJECT => '$(O_FILES)',

	clean  => {FILES => q(
		Devel-Optrace-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
	)},
);
