use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::SearchBox',
    AUTHOR              => 'Ofey Aikon <ofey.aikon@cpan.org>',
    VERSION_FROM        => 'lib/Gtk2/Ex/SearchBox.pm',
    ABSTRACT_FROM       => 'lib/Gtk2/Ex/SearchBox.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Gtk2' => 0,
        'Glib' => 0,
        'Gtk2::Ex::PopupWindow' => 0,        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-SearchBox-*' },
);
