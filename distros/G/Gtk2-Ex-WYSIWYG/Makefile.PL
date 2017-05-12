use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gtk2::Ex::WYSIWYG',
    AUTHOR              => q{Matthew Braid <perl-pkg@mdb.id.au>},
    VERSION_FROM        => 'lib/Gtk2/Ex/WYSIWYG.pm',
    ABSTRACT_FROM       => 'lib/Gtk2/Ex/WYSIWYG.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'XML::Quote' => 0,
        'Gtk2'       => 1.040,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gtk2-Ex-WYSIWYG-*' },
);
