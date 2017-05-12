## no critic(RCS,VERSION,interpolation)
use strict;
use warnings;

use Inline::MakeMaker;

WriteMakefile(
    NAME             => 'Math::Prime::FastSieve',
    VERSION_FROM     => 'lib/Math/Prime/FastSieve.pm',
    ABSTRACT_FROM    => 'lib/Math/Prime/FastSieve.pm',
    AUTHOR           => 'David Oswald <davido [@at] cpan [d.o.t] org>',
    LICENSE          => 'artistic',
    MIN_PERL_VERSION => '5.006000',
    PREREQ_PM        => {
        'Inline::CPP' => '0.42',
        'Inline'      => '0.51',
        'Inline::C'   => '0.51',
    },
    CONFIGURE_REQUIRES => {
        'Inline::MakeMaker'   => '0.51',
        'ExtUtils::MakeMaker' => '6.63',
    },
    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.63',
        'Test::More'          => '0.98',
        'English'             => '0',
    },
    META_MERGE => {
        provides => {
            'Math::Prime::FastSieve' => {
                file    => 'lib/Math/Prime/FastSieve.pm',
                version => '0.19',
            },
        },
    },
);

