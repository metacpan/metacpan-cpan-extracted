use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Imager::Montage',
    AUTHOR              => 'Cornelius <c9s@aiink.com>',
    VERSION_FROM        => 'lib/Imager/Montage.pm',
    ABSTRACT_FROM       => 'lib/Imager/Montage.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Imager' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Imager-Montage-*' },
);
