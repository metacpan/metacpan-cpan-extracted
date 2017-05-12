use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Log::Dispatch::Email::Async',
    AUTHOR           => q{Raja Guha <rajag@cpan.org>},
    VERSION_FROM     => 'lib/Log/Dispatch/Email/Async.pm',
    ABSTRACT_FROM    => 'lib/Log/Dispatch/Email/Async.pm',
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
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Log-Dispatch-Email-Async-*' },
);
