use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Minion::Command::minion::version',
    AUTHOR           => q{Bob Faist <bfaist@cpan.org>},
    VERSION_FROM     => 'lib/Minion/Command/minion/version.pm',
    ABSTRACT_FROM    => 'lib/Minion/Command/minion/version.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.10.1',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Mojolicious'       => '6.0',
        'Minion'            => '6.0'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Minion-Command-minion-version-*' },
);
