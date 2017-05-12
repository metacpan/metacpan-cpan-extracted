use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'MIDI::Trans',
    'VERSION_FROM'	=> 'lib/MIDI/Trans.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'MIDI::Simple' => ''}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/MIDI/Trans.pm', # retrieve abstract from module
       AUTHOR     => 'C. Church <dolljunkie@digitalkoma.com>') : ()),
);
