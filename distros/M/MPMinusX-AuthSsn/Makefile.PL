#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };

my $prereq_pm = {
        'MPMinus'               => 1.17,
        'CTK'                   => 1.12,
        'Apache::Session'       => 1.90,
        'DBD::SQLite'           => 1.40,
    };

WriteMakefile(
    'NAME'                  => 'MPMinusX::AuthSsn',
    'DISTNAME'              => 'MPMinusX-AuthSsn',
    'MIN_PERL_VERSION'      => 5.008001,
    'VERSION_FROM'          => 'lib/MPMinusX/AuthSsn.pm', 
    'ABSTRACT_FROM'         => 'lib/MPMinusX/AuthSsn.pm', ,
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'AUTHOR'                => 'Lepenkov Sergey (Serz Minus) <minus@mail333.com>',
    'LICENSE'               => 'gpl',
    'META_MERGE' => {
        recommends => {
            'DBI'           => 0,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://www.serzik.ru',
            repository      => 'http://svn.serzik.ru/MPMinusX-AuthSsn/trunk',
            license         => 'http://opensource.org/licenses/gpl-license.php',
        },
    },
);

1;
