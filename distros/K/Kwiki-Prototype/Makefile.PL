use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Prototype',
    AUTHOR              => 'Eric Anderson <eric@afaik.us>',
    VERSION_FROM        => 'lib/Kwiki/Prototype.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Prototype.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Prototype-*' },
);
