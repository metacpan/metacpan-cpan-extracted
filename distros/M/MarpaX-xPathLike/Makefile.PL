use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'MarpaX::xPathLike',
    AUTHOR           => q{Isidro Vila Verde <jvverde@gmail.com>},
    VERSION_FROM     => 'lib/MarpaX/xPathLike.pm',
    ABSTRACT_FROM    => 'lib/MarpaX/xPathLike.pod',
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
				'Marpa::R2'					=> 0,
				'Scalar::Util'      => 0,
                'Test::Deep'    => 0,
                'Data::Dumper'  => 0,
                'Carp' => 0,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MarpaX-xPathLike-*' },
);
