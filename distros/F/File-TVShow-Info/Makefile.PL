use 5.10.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'File::TVShow::Info',
    AUTHOR           => q{Adam Spann <bans@cpan.org>},
    VERSION_FROM     => 'lib/File/TVShow/Info.pm',
    ABSTRACT_FROM    => 'lib/File/TVShow/Info.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.10.0',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
    },
    PREREQ_PM => {
    },
    TEST_REQUIRES => {
      'Test::More' => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'File-TVShow-Info-*' },
);
