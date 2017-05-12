use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Kwiki::Theme::BlueOcean',
    AUTHOR              => 'Eric Anderson <eric@cordata.com>',
    VERSION_FROM        => 'lib/Kwiki/Theme/BlueOcean.pm',
    ABSTRACT_FROM       => 'lib/Kwiki/Theme/BlueOcean.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Kwiki-Theme-BlueOcean-*' },
);
