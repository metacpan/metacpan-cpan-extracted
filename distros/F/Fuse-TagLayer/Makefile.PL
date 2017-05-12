

use ExtUtils::MakeMaker;

rename('README.md','README') if -f 'README.md';

WriteMakefile(
	NAME		=> 'Fuse::TagLayer',
	AUTHOR		=> 'Clipland (clipland@cpan.org)',
	ABSTRACT_FROM	=> 'lib/Fuse/TagLayer.pm',
	VERSION_FROM	=> 'lib/Fuse/TagLayer.pm',
	LICENSE		=> 'gpl', # as close as it gets to GPL3+AL2
	PREREQ_PM	=> {
		"Fuse"		=> '0.14',
		"File::ExtAttr"	=> '1.09',
		"Data::Dumper"	=> 0,
	#	"DBI"		=> 0, # only if you want to use the SQLite backend
		"File::Find"	=> 0,
		"File::Basename"=> 0,
		"Fcntl"		=> 0,
		"Getopt::Long"	=> 0,
		"Pod::Usage"	=> 0,
		"POSIX"		=> 0,
	},
	EXE_FILES	=> [
		'bin/taglayer'
	],
	META_MERGE	=> {
		resources	=> {
			repository => {
				url => 'https://github.com/clipland/fuse-taglayer.git',
				web => 'https://github.com/clipland/fuse-taglayer',
				type=> 'git',
			},
		},
	},
	dist => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	realclean => {
		POSTOP => 'perl -e "rename(\'README\',\'README.md\') if -f \'README\'"',
	},
	MIN_PERL_VERSION	=> 5.004, # nothing special in this dist, let's just make CPANTS happier
);
