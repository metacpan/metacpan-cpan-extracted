use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'IO::Ftp',
    'VERSION_FROM'	=> 'Ftp.pm', # finds $VERSION
    'PREREQ_PM'		=> {
	    File::Basename	=> 2.6,
		URI						=> 1.25,
		Symbol				=> 1.02,
		Net::FTP				=> 2.67,
    },
    META_MERGE => {
        x_deprecated => 1,
    },
);
