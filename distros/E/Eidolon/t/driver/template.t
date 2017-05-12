#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/driver/template.t - generic template driver tests
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
    use_ok("Eidolon::Driver::Template");
}

# methods
ok( Eidolon::Driver::Template->can("set"),    "set method"    );
ok( Eidolon::Driver::Template->can("parse"),  "parse method"  );
ok( Eidolon::Driver::Template->can("render"), "render method" );

