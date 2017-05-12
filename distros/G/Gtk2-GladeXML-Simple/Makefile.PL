use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Gtk2::GladeXML::Simple',
    VERSION_FROM      => 'lib/Gtk2/GladeXML/Simple.pm',
    EXE_FILES         => [ "bin/gpsketcher" ],
    PREREQ_PM         => {
			  Gtk2::GladeXML => 0,
			  Gtk2 => 0
			 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Gtk2/GladeXML/Simple.pm',
       AUTHOR         => 'Marco Antonio Manzo <marcoam@perl.org.mx>') : ()),
);
