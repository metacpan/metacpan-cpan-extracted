use strict;
use warnings;
use inc::Module::Install;
#use ExtUtils::Depends;

name 'Method-Destructor';
all_from 'lib/Method/Destructor.pm';

requires 'MRO::Compat';

#my $pkg = ExtUtils::Depends->new('Method::Destructor', 'Devel::MRO');
#makemaker_args($pkg->get_makefile_vars);

test_requires 'Test::More'      => 0.62;
test_requires 'Test::LeakTrace' => 0.08;
test_requires 'parent';

#include 'ExtUtils::Depends';

tests 't/*.t';
author_tests 'xt';

WriteMakefile(
	OBJECT => '$(O_FILES)',

	clean  => {FILES => q(
		Method-Destructor-* *.stackdump
		*.gcda *.gcno *.gcov
		nytprof *.out
		cover_db
	)},
);
