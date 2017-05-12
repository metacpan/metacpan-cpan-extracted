use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Gtk2::Ex::VolumeButton',
    VERSION_FROM      => 'lib/Gtk2/Ex/VolumeButton.pm', # finds $VERSION
    PREREQ_PM         => {
		Gtk2	=> 1.042
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Gtk2/Ex/VolumeButton.pm', # retrieve abstract from module
       AUTHOR         => 'Florian Ragwitz <flora@cpan.org>') : ()),
);
