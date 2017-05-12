#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.008; # utf8 and what not

my $checked_bdb;

if ( eval { require BerkeleyDB } ) {
    do "check_bdb_version.PL";
    die $@ if $@;
    $checked_bdb++;
}

WriteMakefile(
    NAME         => 'KiokuDB::Backend::BDB',
    VERSION_FROM => 'lib/KiokuDB/Backend/BDB.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { $checked_bdb ? () : ( "check_bdb_version.PL" => "check_bdb_version" ) },
    META_MERGE   => { configure_requires => { BerkeleyDB => '0.36' } },
    PREREQ_PM    => {
        'Moose' => 0,
        'MooseX::Types::Path::Class' => 0,

        'KiokuDB' => '0.45',

        'Data::Stream::Bulk' => 0,

        'BerkeleyDB::Manager' => '0.11',
        'BerkeleyDB' => '0.36',

        'Test::use::ok' => 0,
        'Test::More' => 0,
        'Test::TempDir' => 0,

        'Storable' => 0,

        'Search::GIN' => 0,
    },
);

