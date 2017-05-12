use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Math::SparseMatrix::Operations',
    AUTHOR           => q{Felipe da V. Leprevost <leprevost@cpan.org>},
    VERSION_FROM     => 'lib/Math/SparseMatrix/Operations.pm',
    ABSTRACT_FROM    => 'lib/Math/SparseMatrix/Operations.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.012000,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
	'Math::SparseMatrix' => 0.03,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-SparseMatrix-Operations-*' },
);
