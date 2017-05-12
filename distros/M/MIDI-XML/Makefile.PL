use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MIDI::XML',
    VERSION_FROM      => 'lib/MIDI/XML.pm', # finds $VERSION
    PREREQ_PM         => {
        'Carp'        => '1.0',
        'Class::ISA'  => '0.30',
        'Tk'          => '800.0',
#        'Tk::LabEntry'=> '4.0',
        'Tk::Tree'    => '4.0',
        'XML::DOM'    => '1.40',
        'XML::Parser' => '2.0',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MIDI/XML.pm', # retrieve abstract from module
       AUTHOR         => 'Brian M. Ames <bmames@apk.net>') : ()),
);
