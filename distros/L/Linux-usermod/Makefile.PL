use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Linux::usermod',
    'VERSION_FROM'	=> 'usermod.pm', # finds $VERSION
    'PREREQ_PM' => {
    			'Carp' => 0,
			'Test' => 0
		}
);
