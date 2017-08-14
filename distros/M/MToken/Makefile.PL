#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'CTK'                   => 1.18,
        'LWP'                   => 5.80,
        'URI'                   => 1.60,
        'File::HomeDir'         => 1.00,
        'List::MoreUtils'       => 0.416,
        'Digest::MD5'           => 2.54,
        'Digest::SHA1'          => 2.13,
        'JSON'                  => 2.94,
        'CGI'                   => 4.32,
        'File::Spec'            => 3.62,
        'Try::Tiny'             => 0.28,
        'Class::C3::Adopt::NEXT' => 0.14,
        'MRO::Compat'           => 0.13,
        'Config::General'       => 2.63,
        'Archive::Extract'      => 0.80,
        'HTTP::Message'         => 6.11,
    };

my $exefiles = [qw(
        bin/mtoken
    )];


WriteMakefile(
    'NAME'                  => 'MToken',
    'DISTNAME'              => 'MToken',
    'MIN_PERL_VERSION'      => 5.012001,
    'VERSION_FROM'          => 'lib/MToken.pm',
    'ABSTRACT_FROM'         => 'lib/MToken.pm',
    'EXE_FILES'             => $exefiles,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'LICENSE'               => 'GPL',
    'AUTHOR'                => 'Sergey Lepenkov (Serz Minus) <abalama@cpan.org>',
    'META_MERGE' => {
        recommends => {
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://www.serzik.com',
            repository      => 'http://svn.serzik.com/MToken/trunk/',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
    clean                   => {FILES => "ChangeLog"},
);

require File::Copy;
File::Copy::cp("CHANGES", "ChangeLog");
