use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Ham::WSJTX::Logparse',
    AUTHOR           => q{Matt Gumbley <devzendo@cpan.org>},
    VERSION_FROM     => 'lib/Ham/WSJTX/Logparse.pm',
    ABSTRACT_FROM    => 'lib/Ham/WSJTX/Logparse.pm',
    LICENSE          => 'apache_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Ham-WSJTX-Logparse-*' },
);
