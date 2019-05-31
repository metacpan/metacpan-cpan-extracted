#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'MPMinus'               => 1.21,
        'CTK'                   => 2.00,
        'Apache::Session'       => 1.90,
        'DBD::SQLite'           => 1.40,
    };

WriteMakefile(
    'NAME'                  => 'MPMinusX::AuthSsn',
    'MIN_PERL_VERSION'      => 5.016001,
    'VERSION_FROM'          => 'lib/MPMinusX/AuthSsn.pm', 
    'ABSTRACT_FROM'         => 'lib/MPMinusX/AuthSsn.pm', ,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'AUTHOR'                => 'Serz Minus (Sergey Lepenkov) <abalama@cpan.org>',
    'LICENSE'               => 'perl',
    'META_MERGE' => {
        recommends => {
            'DBI'           => 0,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'https://www.serzik.com',
            repository      => 'http://svn.serzik.com/MPMinusX-AuthSsn/trunk',
            license         => 'https://dev.perl.org/licenses',
        },
    },
);

1;
