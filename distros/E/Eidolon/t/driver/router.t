#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/driver/router.t - generic router driver tests
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
    use_ok("Eidolon::Driver::Router");
}

# methods
ok( Eidolon::Driver::Router->can("find_handler"), "find_handler method" );
ok( Eidolon::Driver::Router->can("get_handler"),  "get_handler method"  );
ok( Eidolon::Driver::Router->can("get_params"),   "get_params method"   );

