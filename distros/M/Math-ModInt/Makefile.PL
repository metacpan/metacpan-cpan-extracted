# Copyright (c) 2009-2021 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $DN = 'Math-ModInt';
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
    Math::ModInt
    Math::ModInt::BigInt
    Math::ModInt::ChineseRemainder
    Math::ModInt::Event
    Math::ModInt::Event::Trap
    Math::ModInt::GF2
    Math::ModInt::GF3
    Math::ModInt::Perl
    Math::ModInt::Trivial
);

WriteMakefile(
    NAME               => 'Math::ModInt',
    AUTHOR             => 'Martin Becker <becker-cpan-mp (at) cozap.com>',
    VERSION_FROM       => 'lib/Math/ModInt.pm',
    ABSTRACT_FROM      => 'lib/Math/ModInt.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => '5.006',
    SIGN               => 1,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'File::Spec'          => 0,
    },
    TEST_REQUIRES => {
        'Scalar::Util' => 0,
        'Test'         => 0,
        'Test::More'   => 0,
    },
    PREREQ_PM => {
        'overload'     => 0,
        'Carp'         => 0,
        'Math::BigInt' => '1.991',      # '>= 1.58, != 1.99',
    },
    META_MERGE => {
        'meta-spec'    => { version => 2 },
        provides       => \%versions,
        dynamic_config => 0,
        prereqs => {
            runtime => {
                recommends => {
                    'Math::BigInt::GMP' => 0,
                    'Math::BigRat'      => 0,
                },
            },
        },
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
);

__END__
