#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.008; # utf8 and what not

WriteMakefile(
    NAME         => 'KiokuDB::Backend::Files',
    VERSION_FROM => 'lib/KiokuDB/Backend/Files.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
        'Moose' => 0,
        'KiokuDB' => '0.24',

        'Test::TempDir' => 0,

        'MooseX::Types::Path::Class' => 0,

        'IO' => '1.2301', # binmode method

        'File::Path' => 2.07,
        'Directory::Transactional' => '0.06',
    },
);
