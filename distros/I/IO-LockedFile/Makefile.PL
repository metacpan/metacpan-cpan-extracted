use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IO::LockedFile',
    'VERSION_FROM' => 'LockedFile.pm', # finds $VERSION
    'PREREQ_PM' => {
	IO::File => undef,
	Fcntl => undef },
    'PM' => {'LockedFile.pm'       => '$(INST_LIBDIR)/LockedFile.pm', 
             'LockedFile/Flock.pm' => '$(INST_LIBDIR)/LockedFile/Flock.pm'},
);
