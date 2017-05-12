use strict;
use warnings;
use ExtUtils::MakeMaker;

if($] >= 5.010){
	die "This is a benchmark package only for pre-5.10, stopped.\n";
}

WriteMakefile(
	DISTNAME => 'mro_compat',
	NAME     => 'mro_compat',
	NO_META  => 1,

	INC => q(-I../../),
);
