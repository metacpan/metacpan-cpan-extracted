use ExtUtils::MakeMaker;
use ExtUtils::PkgConfig;
use EV::MakeMaker;

%glib = ExtUtils::PkgConfig->find ("glib-2.0");

my $mm = MM->new({EV::MakeMaker::ev_args (
    dist         => {
       PREOP	=> 'pod2text EV.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "EV::Glib",
    VERSION_FROM => "Glib.pm",
    CCFLAGS      => $glib{cflags},
    LIBS         => [$glib{libs}],
    PREREQ_FATAL => 1,
    PREREQ_PM    => {
       EV                  => 2.0,
       ExtUtils::PkgConfig => 0,
    },
    EXTRA_META => q{
configure_requires:
  ExtUtils::PkgConfig: 0
  EV: 2.0
    },
)});

$mm->flush;

