use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::DBITableFilter',
    AUTHOR              => 'Ofey Aikon <ofey.aikon@gmail.com>',
    VERSION_FROM        => 'lib/Gtk2/Ex/DBITableFilter.pm',
    ABSTRACT_FROM       => 'lib/Gtk2/Ex/DBITableFilter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Gtk2' => 0,
        'Glib' => 0,
        'Data::Dumper' => 0,
        'Carp' => 0,
        'Gtk2::TestHelper' => 0,        
        'Gtk2::Ex::Simple::List' => 0,        
        'Gtk2::Ex::ComboBox' => 0,        
        'Gtk2::Ex::Threads::DBI' => 0,        
        'DBD::CSV' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-DBITableFilter-*' },
);
