use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'GuiBuilder',
    AUTHOR           => q{Sandeep Vaniya <sandeep.vaniya@gmail.com>},
    VERSION_FROM     => 'lib/GuiBuilder.pm',
    ABSTRACT_FROM    => 'lib/GuiBuilder.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'Tk'              => 804.030,
        'Tk::MsgBox'      => 4.002,
        'Tk::Pane'        => 4.007,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Tk'              => 804.030,
        'Tk::MsgBox'      => 4.002,
        'Tk::Pane'        => 4.007,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'zip', },
    clean => { FILES => 'GuiBuilder-*' },
);
