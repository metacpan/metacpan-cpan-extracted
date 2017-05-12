use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'File::MultipleDiff',
    AUTHOR           => q{Mart E. Rivilis <rivilism@cpan.org>},
    VERSION_FROM     => 'lib/File/MultipleDiff.pm',
    ABSTRACT_FROM    => 'lib/File/MultipleDiff.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Algorithm::Diff'  => 1.19,
        'Tie::File'        => 0.97,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'File-MultipleDiff-*' },
);
