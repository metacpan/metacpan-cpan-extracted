use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Getopt::Param::Tiny',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/Getopt/Param/Tiny.pm',
    ABSTRACT_FROM       => 'lib/Getopt/Param/Tiny.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Getopt-Param-Tiny-*' },
);
