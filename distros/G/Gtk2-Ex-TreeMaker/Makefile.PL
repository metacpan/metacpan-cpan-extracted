use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::TreeMaker',
    AUTHOR              => 'Ofey Aikon <ofey.aikon@gmail.com>',
    VERSION_FROM        => 'lib/Gtk2/Ex/TreeMaker.pm',
    ABSTRACT_FROM       => 'lib/Gtk2/Ex/TreeMaker.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Gtk2' => 0,
        'Glib' => 0,
        'Data::Dumper' => 0,
        'Carp' => 0,
        'Gtk2::TestHelper' => 0,        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-TreeMaker-*' },
);
