#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/main.t - basic user driver tests
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
    use_ok("Eidolon::Driver::Exceptions");
    use_ok("Eidolon::Driver::User");
    use_ok("Eidolon::Driver::User::Basic");
}

# methods
ok( Eidolon::Driver::User::Basic->can("authorize"),   "authorize method"   );
ok( Eidolon::Driver::User::Basic->can("unauthorize"), "unauthorize method" );
ok( Eidolon::Driver::User::Basic->can("authorized"),  "authorized method"  );

