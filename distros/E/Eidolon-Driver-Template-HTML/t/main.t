#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/main.t - HTML::Template driver tests
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
    use_ok("Eidolon::Driver::Template::HTML");
}

# methods
ok( Eidolon::Driver::Template::HTML->can("set"),    "set method"    );
ok( Eidolon::Driver::Template::HTML->can("parse"),  "parse method"  );
ok( Eidolon::Driver::Template::HTML->can("render"), "render method" );

