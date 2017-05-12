use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use Event::MakeMaker;

%glib = ExtUtils::PkgConfig->find ("glib-2.0");

my $mm = MM->new({Event::MakeMaker::event_args (
    dist         => {
       PREOP	=> 'pod2text Event.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "Glib::Event",
    VERSION_FROM => "Event.pm",
    CCFLAGS      => $glib{cflags},
    LIBS         => [$glib{libs}],
    PREREQ_FATAL => 1,
    PREREQ_PM    => {
       Event => 1,
       ExtUtils::PkgConfig => 0,
    },
)});

$mm->flush;

