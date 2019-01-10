use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

die "OS unsupported" unless $^O eq 'darwin';

WriteMakefile(
    NAME             => 'Mac::OSA::Dialog::Tiny',
    AUTHOR           => q{LNATION <thisusedtobeanemail@gmail.com>},
    VERSION_FROM     => 'lib/Mac/OSA/Dialog/Tiny.pm',
    ABSTRACT_FROM    => 'lib/Mac/OSA/Dialog/Tiny.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
       'Import::Export' => '1.00',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mac-OSA-Dialog-Tiny-*' },
);
