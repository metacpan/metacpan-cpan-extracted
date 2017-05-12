use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Hexgrid',
    AUTHOR              => 'Zach Morgan <zpmorgan@gmail.com>',
    VERSION_FROM        => 'lib/Gtk2/Hexgrid.pm',
    ABSTRACT_FROM       => 'lib/Gtk2/Hexgrid.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Gtk2'        => 0,
        'Test::More'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Hexgrid-*' },
);
