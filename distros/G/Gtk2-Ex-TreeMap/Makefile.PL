use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::TreeMap',
    AUTHOR              => 'Ofey Aikon <ofey.aikon at gmail dot com>',
    VERSION_FROM        => 'lib/Gtk2/Ex/TreeMap.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Gtk2::TestHelper'	=> '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-TreeMap-*' },
);
