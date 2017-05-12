use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Gtk2::Ex::Dialogs',
    VERSION_FROM      => 'lib/Gtk2/Ex/Dialogs.pm',
    PREREQ_PM         => { 'Gtk2' => 1.040,
                           'Gtk2::Ex::Utils' => 0.08,
                           'File::Type' => 0.22 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Gtk2/Ex/Dialogs.pm',
       AUTHOR         => 'Kevin C. Krinke <kckrinke@opendoorsoftware.com>') : ()),
);
