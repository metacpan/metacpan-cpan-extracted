use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MarpaX::Languages::PowerBuilder',
    AUTHOR           => q{Sébastien Kirche <sebastien.kirche@free.fr>},
    VERSION_FROM     => 'lib/MarpaX/Languages/PowerBuilder.pm',
    ABSTRACT_FROM    => 'lib/MarpaX/Languages/PowerBuilder.pm',
    LICENSE          => 'mit',
    PL_FILES         => {},
    EXE_FILES        => [ 'bin/pbparser_test.pl' ],
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Marpa::R2' => 0,
        'File::Basename' => 0,
        'File::BOM' => 0,
        'Data::Dumper' => 0,        #may be removed
        #~ 'unref' => 0,               #https://github.com/xlat/unref.git
        'Encode' => 0,
        'constant' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MarpaX-Languages-PowerBuilder-*' },
);
