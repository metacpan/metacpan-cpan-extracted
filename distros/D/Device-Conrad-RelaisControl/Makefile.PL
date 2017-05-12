use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Device::Conrad::RelaisControl',
    'VERSION_FROM'	=> 'RelaisControl.pm', # finds $VERSION
    'PREREQ_PM'		=> { Device::SerialPort }, # e.g., Module::Name => 1.1
    'PM' => 
          {
          'RelaisControl.pm' => '$(INST_LIBDIR)/RelaisControl.pm',
          'RelaisCard.pm' => '$(INST_LIBDIR)/RelaisCard.pm',
          'Frame.pm' => '$(INST_LIBDIR)/Frame.pm'
          },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'RelaisControl.pm', # retrieve abstract from module
       AUTHOR     => 'Norbert Hartl <noha@cpan.org>') : ()),
);
