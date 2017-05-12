
use strict;
use warnings;
use inc::Module::Install;
use ExtUtils::Depends;

name 'MyMRO';

author 'Goro Fuji';
license 'perl';

all_from 'MyMRO.pm';

requires 'MRO::Compat' if $] < 5.010_000;
requires 'ExtUtils::Depends';

build_requires 'Test::More' => 0.62;

my $pkg = ExtUtils::Depends->new('MyMRO', 'Devel::MRO');
$pkg->set_inc('-I..');

tests 't/*.t';


WriteMakefile(
	$pkg->get_makefile_vars,
	#FUNCLIST => [qw(mro_get_linear_isa)],

	clean  => {FILES => q(
		MyMRO-* *.stackdump
		*.gcda *.gcno *.gcov
		cover_db
	)},
);
