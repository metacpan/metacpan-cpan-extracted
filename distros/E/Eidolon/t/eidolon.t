#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/eidolon.t - root package tests
#
# ==============================================================================  

use Test::More tests => 2;
use warnings;
use strict;

BEGIN
{
    use_ok("Eidolon");
}

ok( $Eidolon::VERSION, "version check" );

