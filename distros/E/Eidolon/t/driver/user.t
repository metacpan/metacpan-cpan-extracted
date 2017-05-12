#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/driver/user.t - generic user driver tests
#
# ==============================================================================  

use Test::More tests => 5;
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
}

# methods
ok( Eidolon::Driver::User->can("authorize"),   "authorize method"   );
ok( Eidolon::Driver::User->can("unauthorize"), "unauthorize method" );
ok( Eidolon::Driver::User->can("authorized"),  "authorized method"  );

