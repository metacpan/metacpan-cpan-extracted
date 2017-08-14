use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Grid::Layout',
    AUTHOR           => q{René Nyffenegger <rene.nyffenegger@adp-gmbh.ch>},
    VERSION_FROM     => 'lib/Grid/Layout.pm',
    ABSTRACT_FROM    => 'lib/Grid/Layout.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
    },
    BUILD_REQUIRES => {
        'Test::More'      => 0,
        'Test::Files'     => 0,
        'Test::Exception' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Grid-Layout-*' },
);
