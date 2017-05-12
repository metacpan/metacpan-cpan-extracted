use ExtUtils::MakeMaker;
# Bug #52416: 5.6.2 fails with "xref is not of type AVPtr"
# die "5.6.2 unsupported" if $] eq '5.006002';
use 5.006_001;  # 1.16

WriteMakefile(
	NAME      => 'MIDI::ALSA',
	VERSION_FROM => 'ALSA.pm',
	EXE_FILES => [ glob "bin/*" ],
	AUTHOR    => 'PJB, Peter Billam, www.pjb.com.au/comp/contact.html',
	ABSTRACT  => 'Access to the ALSA library',
	LIBS      => ["-lasound"],
	dist      => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
);
