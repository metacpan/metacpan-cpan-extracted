#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/driver/db.t - generic database driver tests
#
# ==============================================================================  

use Test::More tests => 8;
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
}

# methods
ok( Eidolon::Driver::DB->can("execute"),          "execute method"          );
ok( Eidolon::Driver::DB->can("execute_prepared"), "execute_prepared method" );
ok( Eidolon::Driver::DB->can("fetch"),            "fetch method"            );
ok( Eidolon::Driver::DB->can("fetch_all"),        "fetch_all method"        );
ok( Eidolon::Driver::DB->can("free"),             "free method"             );
ok( Eidolon::Driver::DB->can("call"),             "call method"             );

