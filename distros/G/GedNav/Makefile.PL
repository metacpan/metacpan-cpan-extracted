use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'GedNav',
    'VERSION_FROM' => 'GedNav.pm', # finds $VERSION
    PREREQ_PM =>
	{ # I know some of these come with perl, but we can't be too careful
	CGI		=> 0,
	Cwd		=> 0,
	Data::Dumper	=> 0,
	Date::Manip	=> 0,
	File::Basename	=> 0,
	FileHandle	=> 0,
	GDBM_File	=> 0,
	POSIX		=> 0,
	Roman		=> 0,
	Text::Soundex	=> 0,
	},
);
