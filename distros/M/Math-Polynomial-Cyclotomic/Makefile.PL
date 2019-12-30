# Copyright (c) 2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::Spec;

my $DN = 'Math-Polynomial-Cyclotomic';
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
    Math::Polynomial::Cyclotomic
);

WriteMakefile(
    NAME             => 'Math::Polynomial::Cyclotomic',
    AUTHOR           => 'Martin Becker <becker-cpan-mp (at) cozap.com>',
    VERSION_FROM     => 'lib/Math/Polynomial/Cyclotomic.pm',
    ABSTRACT_FROM    => 'lib/Math/Polynomial/Cyclotomic.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'File::Spec'          => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp'              => '0',
        'Exporter'          => '0',
        'Math::Polynomial'  => '1.001',
        'Math::Prime::Util' => '0.36',
    },
    SIGN => 1,
    META_MERGE => {
        'meta-spec'    => { version => 2 },
        provides       => \%versions,
        dynamic_config => 0,
        resources      => {
            bugtracker => {
                web => "https://rt.cpan.org/Public/Dist/Display.html?Name=$DN",
            },
            license => [
                'https://www.perlfoundation.org/artistic-license-20.html'
            ],
            repository => {
                url  => "git://github.com/mhasch/perl-$DN.git",
                web  => "https://github.com/mhasch/perl-$DN",
                type => 'git',
            },
        },
    },
);

__END__
