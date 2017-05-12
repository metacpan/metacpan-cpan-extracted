
use 5.010000;

use ExtUtils::MakeMaker;
BEGIN {
	eval 'use ExtUtils::MakeMaker::Coverage';
}

WriteMakefile(
	NAME => 'Logfile::Tail',
	LICENSE => 'GPLv2+ or Artistic_2',
	VERSION_FROM => 'lib/Logfile/Tail.pm',
	PREREQ_PM => {
		'Digest::SHA' => 0,
		'Test::More' => 0,
	},
	EXE_FILES => [ 'bin/logfile-tail', ],
	clean => {
		FILES => [
			'cover_db',
			't/file',
			't/rotate*',
			't/rotfail*',
			't/status-file2',
			'.logfile-tail-status',
			'logfile-status-file',
			'.logfile-test3',
		],
	},
	dist => {
		POSTOP => 'mv $(DISTNAME)-$(VERSION).tar.gz ../'
	},
);

