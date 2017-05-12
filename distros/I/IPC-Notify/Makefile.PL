use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IPC::Notify',
    VERSION           => '0.2',
    PREREQ_PM         => {
			'File::Temp' => 0,
			'Carp'       => 0,
			},
	AUTHOR            => 'Jason Long <jason@long.name>',
);
