use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Decision::Markov',
    'VERSION_FROM' => 'Markov.pm', # finds $VERSION
    'dist' => {TARFLAGS => 'cvfF', COMPRESS => 'gzip', SUFFIX => 'gz',
		DIST_CP => 'best' },
);

sub MY::dist_dir {
'
distdir:
	$(RM_RF) $(DISTVNAME)
	$(MKPATH) $(DISTVNAME)
	cd $(DISTVNAME) && prcs checkout $(DISTNAME)
	cd $(DISTVNAME) && $(RM_RF) $(DISTNAME).prj
';
}


sub MY::dist_ci {
'
ci:
	prcs checkin
';
}

