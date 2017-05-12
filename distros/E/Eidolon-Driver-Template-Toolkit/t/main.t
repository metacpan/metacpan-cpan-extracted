#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/main.t - Template::Toolkit driver tests
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
    use_ok("Eidolon::Driver::Template");
    use_ok("Eidolon::Driver::Template::Toolkit");
}

# methods
ok( Eidolon::Driver::Template::Toolkit->can("set"),    "set method"    );
ok( Eidolon::Driver::Template::Toolkit->can("parse"),  "parse method"  );
ok( Eidolon::Driver::Template::Toolkit->can("render"), "render method" );

