# Copyright (c) 2011-2017 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Math::Polynomial::Multivariate',
    VERSION_FROM        => 'lib/Math/Polynomial/Multivariate.pm',
    PREREQ_PM           => {
        'overload'      => 0,
        'Carp',         => 0,
    },
    ABSTRACT_FROM       => 'lib/Math/Polynomial/Multivariate.pm',
    AUTHOR              => 'Martin Becker <becker-cpan-mp@cozap.com>',
    $ExtUtils::MakeMaker::VERSION >= 6.18? (
        SIGN            => 1,
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.31? (
        LICENSE         => 'perl',
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.46? (
        META_MERGE => {
            'meta-spec' => {
                url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
                version => 2,
            },
            provides => {
                'Math::Polynomial::Multivariate' => {
                    file    => 'lib/Math/Polynomial/Multivariate.pm',
                    version => '0.006',
                },
            },
            prereqs => {
                runtime => {
                    suggests => {
                        'Math::BigRat' => '0.2613',
                    },
                },
            },    
        },        
    ): (),        
    $ExtUtils::MakeMaker::VERSION >= 6.47? (
        MIN_PERL_VERSION => '5.008',
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.56? (
        BUILD_REQUIRES => {
            'ExtUtils::MakeMaker' => 0,
            'Test::More'          => 0,
        }, 
    ): (),
);
