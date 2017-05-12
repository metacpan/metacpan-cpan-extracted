use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::ICal::Recur',
    AUTHOR              => 'Ofey Aikon <ofey.aikon@gmail.com>',
    VERSION_FROM        => 'lib/Gtk2/Ex/ICal/Recur.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Gtk2' => 0,
        'Gtk2::Ex::Simple::Menu' => 0,
        'Gtk2::Ex::Simple::List' => 0,
        'Gtk2::Ex::ICal::Recur::Selection' => 0,
        'Gtk2::Ex::CalendarButton' => 0,
        'DateTime::Event::ICal' => 0,
        'Glib' => 0,
        'Data::Dumper' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-ICal-Recur-*' },
);
