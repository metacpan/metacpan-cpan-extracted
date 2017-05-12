use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Math::DWT::UDWT',
    AUTHOR           => q{Mike Kroh <kroh@cpan.org>},
    VERSION_FROM     => 'lib/Math/DWT/UDWT.pm',
    ABSTRACT_FROM    => 'lib/Math/DWT/UDWT.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 1,
    },
    PREREQ_PM => {
	#'Math::DWT'	=> 0.1,
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-DWT-UDWT-*' },
);
