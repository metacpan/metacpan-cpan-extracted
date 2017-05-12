#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/main.t - PostgreSQL database driver tests
#
# ==============================================================================  

use Test::More tests => 9;
use warnings;
use strict;

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Driver::Exceptions");
    use_ok("Eidolon::Driver::DB");
    use_ok("Eidolon::Driver::DB::PostgreSQL");
}

# methods
ok( Eidolon::Driver::DB::PostgreSQL->can("execute"),          "execute method"          );
ok( Eidolon::Driver::DB::PostgreSQL->can("execute_prepared"), "execute_prepared method" );
ok( Eidolon::Driver::DB::PostgreSQL->can("fetch"),            "fetch method"            );
ok( Eidolon::Driver::DB::PostgreSQL->can("fetch_all"),        "fetch_all method"        );
ok( Eidolon::Driver::DB::PostgreSQL->can("free"),             "free method"             );
ok( Eidolon::Driver::DB::PostgreSQL->can("call"),             "call method"             );

