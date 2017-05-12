use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Device::TLSPrinter',
    LICENSE             => 'perl',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/Device/TLSPrinter.pm',
    ABSTRACT_FROM       => 'lib/Device/TLSPrinter.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        # prereqs
        'Class::Accessor'   => '0.31',
        'IO'                => '1.23',

        # build/test prereqs
        'Test::More'        => '0.70',
    },
    META_MERGE => {
        resources       => {
            repository  => "https://github.com/maddingue/Device-TLSPrinter.git",
        }
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Device-TLSPrinter-*' },
);
