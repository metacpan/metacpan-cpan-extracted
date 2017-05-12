use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use EV::MakeMaker;

%glib = ExtUtils::PkgConfig->find ("glib-2.0");

WriteMakefile(EV::MakeMaker::ev_args (
    dist         => {
       PREOP	=> 'pod2text EV.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "Glib::EV",
    VERSION_FROM => "EV.pm",
    CCFLAGS      => $glib{cflags},
    LIBS         => [$glib{libs}],
    PREREQ_FATAL => 1,
    PREREQ_PM    => {
       EV                  => 4.00,
       ExtUtils::PkgConfig => 0,
    },
    CONFIGURE_REQUIRES => {
       EV                  => 4.00,
       ExtUtils::PkgConfig => 0,
    },
));
