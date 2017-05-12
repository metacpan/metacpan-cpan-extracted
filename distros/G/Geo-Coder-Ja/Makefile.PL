use strict;
use warnings;
use ExtUtils::MakeMaker;

link('lib/Geo/Coder/Ja.xs', 'Ja.xs');
WriteMakefile(
    NAME                => 'Geo::Coder::Ja',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/Geo/Coder/Ja.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0.32,
    },
    LIBS                => '-L/usr/local/lib -lgeocoderja',
    CCFLAGS             => '-I/usr/local/include -Isrc',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-Coder-Ja-*' },
);
