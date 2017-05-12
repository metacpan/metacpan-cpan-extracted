use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::Threads::DBI',
    AUTHOR              => '=Ofey Aikon <ofey.aikon@gmail.com>',
    VERSION_FROM        => 'lib/Gtk2/Ex/Threads/DBI.pm',
    ABSTRACT_FROM       => 'lib/Gtk2/Ex/Threads/DBI.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBI' => 0,
        'Storable' => 0,
        'Gtk2' => 0,
        'Glib' => 0,
        'DBD::CSV' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-Threads-DBI-*' },
);
