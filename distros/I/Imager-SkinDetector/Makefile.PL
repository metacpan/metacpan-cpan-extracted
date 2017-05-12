use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Imager::SkinDetector',
    AUTHOR              => 'Cosimo Streppone <cosimo@cpan.org>',
    VERSION_FROM        => 'lib/Imager/SkinDetector.pm',
    ABSTRACT_FROM       => 'lib/Imager/SkinDetector.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0, 
        'Imager'     => 0,
        'File::Temp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Imager-SkinDetector-*' },
);
