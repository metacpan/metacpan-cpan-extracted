#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/main.t - MySQL database driver tests
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
    use_ok("Eidolon::Driver::DB::MySQL");
}

# methods
ok( Eidolon::Driver::DB::MySQL->can("execute"),          "execute method"          );
ok( Eidolon::Driver::DB::MySQL->can("execute_prepared"), "execute_prepared method" );
ok( Eidolon::Driver::DB::MySQL->can("fetch"),            "fetch method"            );
ok( Eidolon::Driver::DB::MySQL->can("fetch_all"),        "fetch_all method"        );
ok( Eidolon::Driver::DB::MySQL->can("free"),             "free method"             );
ok( Eidolon::Driver::DB::MySQL->can("call"),             "call method"             );

