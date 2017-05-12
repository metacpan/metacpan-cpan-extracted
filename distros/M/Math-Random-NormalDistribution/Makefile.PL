use 5.008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Math::Random::NormalDistribution',
    AUTHOR           => q{Oleg Alistratov <zero@cpan.org>},
    VERSION_FROM     => 'lib/Math/Random/NormalDistribution.pm',
    ABSTRACT_FROM    => 'lib/Math/Random/NormalDistribution.pm',
    LICENSE          => 'Artistic_2_0',

    META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'https://github.com/alistratov/math-random-normaldistribution.git',
          web => 'https://github.com/alistratov/math-random-normaldistribution',
        },
      },
    },

    PL_FILES         => {},
    INSTALLDIRS      => 'site',
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Math-Random-NormalDistribution-*' },
);
