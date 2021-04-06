# Copyright (c) 2008-2021 by Martin Becker, Blaubeuren.
# This library is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see the LICENSE file).

use strict;
use ExtUtils::MakeMaker;
use File::Spec;

my $DN = 'Math-Polynomial';
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
    SIGN           => 1,
    LICENSE        => 'artistic_2',
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
        resources => {
            bugtracker => {
                web => "https://github.com/mhasch/perl-$DN/issues",
            },
            license => [
                'https://www.perlfoundation.org/artistic-license-20.html',
            ],
            repository => {
                url  => "git://github.com/mhasch/perl-$DN.git",
                web  => "https://github.com/mhasch/perl-$DN",
                type => 'git',
            }
        },
    },
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'File::Spec'          => 0,
    },
    TEST_REQUIRES => {
        'Test'                => 0,
    },
);
