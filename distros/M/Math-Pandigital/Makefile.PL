## no critic (RCS,VERSION)


BEGIN{ require 5.006_002; }

use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

## no critic (may require interpolation)
WriteMakefile(
    NAME               => 'Math::Pandigital',
    AUTHOR             => q{David Oswald <davido [@at] cpan [d.o.t] org>},
    VERSION_FROM       => 'lib/Math/Pandigital.pm',
    ABSTRACT_FROM      => 'lib/Math/Pandigital.pm',
    LICENSE            => 'perl',
    MIN_PERL_VERSION   => '5.006002',
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
      'ExtUtils::MakeMaker' => '6.30',      # Core, but we need a modern versn.
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.98',             # Core, but specify a minimum versn.
        'English'    => '0',                # Core.
    },
    PREREQ_PM => {
        'Moo'                     => '1.000007',
        'MooX::Types::MooseLike'  => '0.16',
    },
    META_MERGE => {
        provides => {
            'Math::Pandigital' => {
                file    => 'lib/Math/Pandigital.pm',
                version => '0.04'
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Math-Pandigital-*' },
);
