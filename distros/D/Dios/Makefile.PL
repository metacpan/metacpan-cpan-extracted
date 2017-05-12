use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                 => 'Dios',
    AUTHOR               => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM         => 'lib/Dios.pm',
    ABSTRACT_FROM        => 'lib/Dios.pm',
    PL_FILES             => {},
    LICENSE              => 'artistic2',
    MIN_PERL_VERSION     => 5.014,
    TEST_REQUIRES => {
        'Test::More'       => 0,
        'Test::Warn'       => 0,
        'Test::Exception'  => 0,
    },
    PREREQ_PM => {
        'Object::InsideOut' => 0,
        'Const::Fast'       => 0,
        'Data::Dump'        => 0,
    ( $] < 5.022 ? (
        'Data::Alias'       => 0,
    ) : () ),
        'Variable::Magic'   => 0.59,
        'Keyword::Declare'  => 0,
        'Sub::Uplevel'      => 0.24,
    },
    dist                 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean                => { FILES => 'Dios-*' },
);
