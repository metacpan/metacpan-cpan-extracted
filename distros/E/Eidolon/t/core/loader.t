#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/core/loader.t - driver loader tests
#
# ==============================================================================  

use Test::More tests => 6;
use warnings;
use strict;

my ($loader, $object);

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Core::Registry");
    use_ok("Eidolon::Core::Loader");
}

# methods
ok( Eidolon::Core::Loader->can("load"),       "load method"       );
ok( Eidolon::Core::Loader->can("get_object"), "get_object method" );

# driver loading
$loader = Eidolon::Core::Loader->new;
$loader->load("Eidolon::Driver::Router");
$object = $loader->get_object("Eidolon::Driver::Router");

ok( $object,                                "driver loading" );
is( ref $object, "Eidolon::Driver::Router", "object type"    );

