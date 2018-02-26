use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::Template::Nest',
    VERSION_FROM      => 'lib/HTML/Template/Nest.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { 
		'HTML::Template' => 0, 
		'Carp' => 0,
		'Data::Dumper' => 0,
		'File::Spec' => 0	
	},
    ABSTRACT_FROM     => 'lib/HTML/Template/Nest.pm', # retrieve abstract from module
    AUTHOR            => 'Tom Gracey <tomgracey@gmail.com>',
    LICENSE           => 'perl',
);
