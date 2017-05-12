#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/core/registry.t - registry tests
#
# ==============================================================================  

use Test::More tests => 6;
use warnings;
use strict;

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Core::Registry");
}

# methods
ok( Eidolon::Core::Registry->can("get_instance"), "get_instance method" );
ok( Eidolon::Core::Registry->can("free"),         "free method"         );

# accessors
ok( Eidolon::Core::Registry->can("cgi"),          "cgi accessor"        );
ok( Eidolon::Core::Registry->can("config"),       "config accessor"     );
ok( Eidolon::Core::Registry->can("loader"),       "loader accessor"     );
