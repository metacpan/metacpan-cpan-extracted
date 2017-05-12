use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

name 'Devel-MRO';
all_from 'lib/Devel/MRO.pm';

build_requires 'ExtUtils::Depends';

build_requires 'Test::More' => 0.62;

my $pkg = ExtUtils::Depends->new('Devel::MRO');

if($] < 5.010_000){
	requires 'MRO::Compat';

	# XXX: $pkg->add_deps('MRO::Compat') does not work.
}

$pkg->add_pm('lib/Devel/MRO.pm' => '$(INST_LIB)/Devel/MRO.pm');
$pkg->install('mro_compat.h');

mkdir 'xsdepends';
$pkg->save_config('xsdepends/Files.pm');

tests 't/*.t';
author_tests 'xt';

no_index directory => 'example';
no_index directory => 'benchmark';

include 'ExtUtils::Depends';

WriteMakefile(
	$pkg->get_makefile_vars,

	clean  => {FILES => q(
		Devel-MRO-* *.stackdump
		*.gcda *.gcno *.gcov
		cover_db
		xsdepends
	)},
);
