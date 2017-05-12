use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      => 'Math::Evol',
	VERSION_FROM => 'Evol.pm',
	EXE_FILES => [ glob "bin/*" ],
	AUTHOR    => 'PJB, Peter Billam, www.pjb.com.au/comp/contact.html',
	ABSTRACT  => 'Evolution Search Algorithm',
	dist      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
);
