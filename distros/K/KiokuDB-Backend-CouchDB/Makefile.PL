#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.008; # utf8 and what not

WriteMakefile(
    NAME         => 'KiokuDB::Backend::CouchDB',
    VERSION_FROM => 'lib/KiokuDB/Backend/CouchDB.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    EXE_FILES    => [ grep { /\w$/ } glob("bin/*") ],
    PREREQ_PM    => {
        'Moose' => 0,
        'KiokuDB' => 0.24,
        'AnyEvent::CouchDB' => 1.07,
        'Data::Stream::Bulk' => 0,
        'Data::Dmap' => 0.08,
        'Scope::Guard' => 0,
    },
);
