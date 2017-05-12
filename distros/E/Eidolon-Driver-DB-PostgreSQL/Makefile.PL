#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Makefile.PL - makefile maker
#
# ==============================================================================  

use 5.008008;
use ExtUtils::MakeMaker;
use warnings;
use strict;

WriteMakefile
(
    "NAME"          => "Eidolon::Driver::DB::PostgreSQL",
    "ABSTRACT_FROM" => "lib/Eidolon/Driver/DB/PostgreSQL.pm",
    "VERSION_FROM"  => "lib/Eidolon/Driver/DB/PostgreSQL.pm", 
    "AUTHOR"        => "Anton Belousov <abel\@cpan.org>",

    "PREREQ_PM"     => 
    {
        "DBI"     => 0,
        "DBD::Pg" => 0,
        "Eidolon" => "0.02"
    }, 

    "test"          => { "TESTS" => "t/*.t" },
);

