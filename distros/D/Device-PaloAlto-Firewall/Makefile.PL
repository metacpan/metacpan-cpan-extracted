use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Device::PaloAlto::Firewall',
    AUTHOR           => q{Greg Foletta <greg@foletta.org>},
    VERSION_FROM     => 'lib/Device/PaloAlto/Firewall.pm',
    ABSTRACT_FROM    => 'lib/Device/PaloAlto/Firewall.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Exception' => 0,
        'Test::Warn' => 0,
        'XML::Twig' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Device-PaloAlto-*' },
);
