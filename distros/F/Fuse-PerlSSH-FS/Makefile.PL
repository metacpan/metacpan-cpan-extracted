

use ExtUtils::MakeMaker;

rename('README.md','README') if -f 'README.md';

WriteMakefile(
	NAME		=> 'Fuse::PerlSSH::FS',
	AUTHOR		=> 'Clipland (clipland@cpan.org)',
	ABSTRACT	=> 'Mount a remote filesystem via FUSE + PerlSSH',
	VERSION_FROM	=> 'lib/Fuse/PerlSSH/FS.pm', # finds \$VERSION
	LICENSE		=> 'gpl', # as close as it gets to GPL3+AL2
	PREREQ_PM	=> {
		'Fuse'		=> '0.14',
		'File::ExtAttr'	=> '1.09',
		'IPC::PerlSSH'	=> '0.16',
		'Getopt::Long'	=> 0,
		'Pod::Usage'	=> 0,
		'Data::Dumper'	=> 0,
		'Daemon::Daemonize'	=> 0,
		'Fcntl'		=> 0,
		'POSIX'		=> 0,
	},
	BUILD_REQUIRES	=> {
		'Test::Virtual::Filesystem'	=> 0,
	},
	EXE_FILES	=> [
		'bin/perlsshfs'
	],
	META_MERGE	=> {
		resources	=> {
			repository => 'https://github.com/clipland/fuse-perlssh-fs',
		},
	},
	dist => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	realclean => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
);
