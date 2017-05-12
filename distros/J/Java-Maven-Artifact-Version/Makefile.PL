use 5.008008;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Java::Maven::Artifact::Version',
    AUTHOR           => q{Thomas Cazali <pandragon@cpan.org>},
    VERSION_FROM     => 'lib/Java/Maven/Artifact/Version.pm',
    ABSTRACT_FROM    => 'lib/Java/Maven/Artifact/Version.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.008008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'         => 0,
        'Scalar::Util' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Java-Maven-Artifact-Version-*' },
    META_MERGE => {
      'meta-spec'    => { version => 2 },
      license        => ['artistic_2'],
      dynamic_config => 0,
      resources      => {
        homepage    => 'https://github.com/apendragon/Java-Maven-Artifact-Version/wiki',
        license     => ['https://github.com/apendragon/Java-Maven-Artifact-Version/blob/master/LICENSE'],
        repository  => {
          type   => 'git',
          url    => 'git://github.com/apendragon/Java-Maven-Artifact-Version.git',
          web    => 'https://github.com/apendragon/Java-Maven-Artifact-Version.git',
        },
        bugtracker  => {
          web    => 'https://github.com/apendragon/Java-Maven-Artifact-Version/issues',
          mailto => 'pandragon@cpan.org',
        },
      },
    },
);
