use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Java',
    'VERSION_FROM'	=> 'Java.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    'PPM_INSTALL_EXEC'	=> 'perl',
    'PPM_INSTALL_SCRIPT'=> 'java_server_install.pl',
	'EXE_FILES'	=> ['java_server_install.pl'],
);
