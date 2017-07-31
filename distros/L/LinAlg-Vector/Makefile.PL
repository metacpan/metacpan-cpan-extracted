use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'LinAlg::Vector',
    AUTHOR           => q{Samuel Steffl <sam@ssteffl.com>},
    VERSION_FROM     => 'lib/LinAlg/Vector.pm',
    ABSTRACT_FROM    => 'lib/LinAlg/Vector.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Package::Alias' => '0',
        'Test::More' => '0',
        'Test::Exception' => '0',
        'Test::Pod' => '0',
        'Test::Pod::Coverage' => '0',
        'Test::CheckManifest' => '0',
    },
    PREREQ_PM => {
        'Math::Round' => '0',
        'Moose' => '0',
        'Params::Check::Item' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LinAlg-Vector-*' },
);
