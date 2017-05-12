use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Gtk2::Ex::FormFactory::TimeEntry',
    VERSION_FROM      => 'lib/Gtk2/Ex/FormFactory/TimeEntry.pm', # finds $VERSION
    PREREQ_PM         => {  Gtk2::Ex::FormFactory => 0,
                            Gtk2::Ex::TimeEntry   => 0}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => ' A Gtk2::Ex::TimeEntry in a FormFactory framework',
       AUTHOR         => 'Jeffrey Ray Hallock < jeffrey at jeffrey.ray dot info >') : ()),
);
