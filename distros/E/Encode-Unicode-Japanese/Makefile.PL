use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Encode::Unicode::Japanese',
    AUTHOR              => 'YAMASHINA Hio <hio@hio.jp>',
    VERSION_FROM        => 'lib/Encode/Unicode/Japanese.pm',
    ABSTRACT_FROM       => 'lib/Encode/Unicode/Japanese.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Unicode::Japanese' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Encode-Unicode-Japanese-*' },
);
