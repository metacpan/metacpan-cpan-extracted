use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Jcode::CP932',
    AUTHOR              => 'ASAKURA Takuji <asakura.takuji+cpan@gmail.com>',
    VERSION_FROM        => 'lib/Jcode/CP932.pm',
    ABSTRACT_FROM       => 'lib/Jcode/CP932.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Jcode'           => 2.00,
        'Encode::EUCJPMS' => 0.07,
        'B::Deparse' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Jcode-CP932-*' },
);
