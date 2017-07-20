use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::Template::Nest',
    VERSION_FROM      => 'lib/HTML/Template/Nest.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { 
		'HTML::Template' => '2.1', 
		'Carp' => '1.22',
		'Data::Dumper' => '2.101',
		'File::Spec' => '3.26'	
	},
    ABSTRACT_FROM     => 'lib/HTML/Template/Nest.pm', # retrieve abstract from module
    AUTHOR            => 'Tom Gracey <tomgracey@gmail.com>',
    LICENSE           => 'perl',
);
