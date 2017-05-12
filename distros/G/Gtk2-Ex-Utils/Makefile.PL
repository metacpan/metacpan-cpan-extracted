use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Gtk2::Ex::Utils',
    VERSION_FROM      => 'lib/Gtk2/Ex/Utils.pm', # finds $VERSION
    PREREQ_PM         => { 'Gtk2' => 1.040 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Gtk2/Ex/Utils.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin C. Krinke <kckrinke@opendoorsoftware.com>') : ()),
);
