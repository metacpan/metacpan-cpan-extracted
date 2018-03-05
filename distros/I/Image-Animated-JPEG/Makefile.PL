

use ExtUtils::MakeMaker;

rename('README.md','README') if -f 'README.md';

WriteMakefile(
	NAME		=> 'Image::Animated::JPEG',
	AUTHOR		=> 'Clipland (clipland@cpan.org)',
	ABSTRACT_FROM	=> 'lib/Image/Animated/JPEG.pm',
	VERSION_FROM	=> 'lib/Image/Animated/JPEG.pm',
	LICENSE		=> 'gpl', # as close as it gets to GPL3+AL2
	PREREQ_PM	=> {
		"IO::String"	=> 0,
		"Image::MetaData::JPEG"	=> 0,
		"Data::Dumper"	=> 0,
		"IPC::System::Simple"	=> 0,
	},
	TEST_REQUIRES	=> {
		'Test::More'		=> 0,
		'Test::Deep'		=> 0,
	},
	EXE_FILES	=> [
		'bin/makeajpeg',
		'bin/playajpeg',
		'bin/gif2ajpeg',
		'bin/ajpeg2gif',
		'bin/ajpegtran'
	],
	META_MERGE	=> {
		'meta-spec'	=> { version => 2 },
		resources	=> {
			repository => {
				type=> 'git',
				url => 'https://github.com/clipland/animated-jpeg.git',
				web => 'https://github.com/clipland/animated-jpeg',
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
