use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Filesys::Virtual::Plain',
    'VERSION_FROM'	=> 'Plain.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Filesys::Virtual' => 0.05,
    	'User::pwent' => undef,
    	'User::grent' => undef,
		'IO::File' => undef,
    }, # e.g., Module::Name => 1.1
	'dist'         => {
		'SUFFIX'       => ".gz",
		'DIST_DEFAULT' => 'all tardist',
		'COMPRESS'     => "gzip -9vf",
	},
);
