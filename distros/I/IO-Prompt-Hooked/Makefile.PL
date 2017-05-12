## no critic (RCS,VERSION)

use strict;
use warnings;

use ExtUtils::MakeMaker;

## no critic (may require interpolation)
WriteMakefile(
    NAME               => 'IO::Prompt::Hooked',
    AUTHOR             => q{David Oswald <davido [@at] cpan [d.o.t] org>},
    VERSION_FROM       => 'lib/IO/Prompt/Hooked.pm',
    ABSTRACT_FROM      => 'lib/IO/Prompt/Hooked.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => '5.006000',
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.62',    # Core, but updated version.
    },
    BUILD_REQUIRES => {
        'Test::More'    => '0.98',          # Core, but updated version.
        'English'       => '0',             # Core. Used in tests.
        'Capture::Tiny' => '0',             # Used in testing.
    },
    PREREQ_PM => {
        'Params::Smart'    => '0.08',
        'parent'           => '0.225',
        'IO::Prompt::Tiny' => '0.001',
    },
    META_MERGE => {
        provides => {
            'IO::Prompt::Hooked' => {
                file    => 'lib/IO/Prompt/Hooked.pm',
                version => '0.10',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'IO-Prompt-Hooked-*' },
);
