# Copyright (c) 2008-2019 by Martin Becker, Blaubeuren.
# This library is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see the LICENSE file).

use strict;
use ExtUtils::MakeMaker;
use File::Spec;

my %versions = map {
    my $module = $_;
    my @path   = ('lib', split /::/, "$module.pm");
    my $file   = join '/', @path;
    my $osfile = File::Spec->catfile(@path);
    $module => {
        file    => $file,
        version => MM->parse_version($osfile),
    }
} qw(
    Math::Polynomial
    Math::Polynomial::Generic
);

WriteMakefile(
    NAME           => 'Math::Polynomial',
    VERSION_FROM   => 'lib/Math/Polynomial.pm',
    PREREQ_PM      => {
        overload   => 0,
        Carp       => 0,
    },
    ABSTRACT_FROM  => 'lib/Math/Polynomial.pm',
    AUTHOR         => 'Martin Becker <becker-cpan-mp (at) cozap.com>',
    $ExtUtils::MakeMaker::VERSION >= 6.18? (
        SIGN       => 1,
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.31? (
        LICENSE    => 'artistic_2',
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.46? (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            dynamic_config => 0,
            prereqs => {
                runtime => {
                    recommends => {
                        'Math::Complex'       => 0,
                        'Math::AnyNum'        => 0,
                        'Math::ModInt'        => 0,
                    },
                },
            },
            provides => \%versions,
        },
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.47? (
        MIN_PERL_VERSION => '5.006',
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.52? (
        CONFIGURE_REQUIRES => {
            'ExtUtils::MakeMaker' => 0,
            'File::Spec'          => 0,
        },
    ): (),
    $ExtUtils::MakeMaker::VERSION >= 6.64? (
        TEST_REQUIRES => {
            'Test'                => 0,
        },
    ): (),
);
