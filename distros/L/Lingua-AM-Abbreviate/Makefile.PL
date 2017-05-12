use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'			=> 'Lingua::AM::Abbreviate',
    'VERSION_FROM'	=> 'Abbreviate.pm', # finds $VERSION
	'DISTNAME'		=> 'Lingua-AM-Abbreviate',
	'dist'			=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../' },
);
