use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Image::Mate',
    AUTHOR              => 'Lyle Hopkins <webmaster@cosmicperl.com>',
    VERSION_FROM        => 'lib/Image/Mate.pm',
    ABSTRACT_FROM       => 'lib/Image/Mate.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Image-Mate-*' },
);
