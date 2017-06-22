# Copyright (c) 2008-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Math::Polynomial',
    VERSION_FROM   => 'lib/Math/Polynomial.pm',
    PREREQ_PM      => {
        overload   => 0,
        Carp       => 0,
    },
    ABSTRACT_FROM  => 'lib/Math/Polynomial.pm',
    AUTHOR         => 'Martin Becker <becker-cpan-mp@cozap.com>',
    $ExtUtils::MakeMaker::VERSION >= 6.18? (
        SIGN       => 1,
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.31? (
        LICENSE    => 'perl',
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.46? (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            prereqs => {
                runtime => {
                    recommends => {
                        'Math::Complex'       => 0,
                        'Math::BigNum'        => 0,
                        'Math::ModInt'        => 0,
                    },
                },
            },
            provides => {
                'Math::Polynomial' => {
                    file    => 'lib/Math/Polynomial.pm',
                    version => '1.013',
                },
                'Math::Polynomial::Generic' => {
                    file    => 'lib/Math/Polynomial/Generic.pm',
                    version => '1.013',
                },
            },
        },
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.47? (
        MIN_PERL_VERSION => '5.006',
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.56? (
        BUILD_REQUIRES => {
            'Test'                => 0,
            'ExtUtils::MakeMaker' => 0,
        },
    ): (),
);
