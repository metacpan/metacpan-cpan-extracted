use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::RecordsFilter',
    AUTHOR              => 'Ofey Aikon <ofey_aikon@gmail.com>',
    VERSION_FROM        => 'lib/Gtk2/Ex/RecordsFilter.pm',
    ABSTRACT_FROM       => 'lib/Gtk2/Ex/RecordsFilter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-RecordsFilter-*' },
);
