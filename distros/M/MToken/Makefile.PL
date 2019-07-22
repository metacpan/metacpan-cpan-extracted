#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'Archive::Extract'      => 0.80,
        'CGI'                   => 4.32,
        'CTK'                   => 2.00,
        'Digest::MD5'           => 2.54,
        'Digest::SHA1'          => 2.13,
        'File::HomeDir'         => 1.00,
        'File::Spec'            => 3.62,
        'HTTP::Message'         => 6.11,
        'LWP'                   => 5.80,
        'LWP::Protocol::https'  => 6.00,
        'Try::Tiny'             => 0.20,
        'URI'                   => 1.70,
    };

my $exefiles = [qw(
        bin/mtoken
    )];

WriteMakefile(
    'NAME'                  => 'MToken',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/MToken.pm',
    'ABSTRACT_FROM'         => 'lib/MToken.pm',
    'EXE_FILES'             => $exefiles,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'LICENSE'               => 'perl',
    'AUTHOR'                => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'META_MERGE' => { 'meta-spec' => { version => 2 },
        recommends => {
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'https://www.serzik.com',
            repository      => 'http://svn.serzik.com/MToken/trunk/',
            license         => 'https://dev.perl.org/licenses',
        },
    },
);
