use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Filter::decrypt',
	VERSION_FROM   => 'decrypt.pm',

	# The line below disables both the dynamic link test and the
	# test for DEBUGGING.
	# It is only enabled here to allow the decrypt test harness
	# to run without having to build statically.
	DEFINE	  => "-DBYPASS",
);
