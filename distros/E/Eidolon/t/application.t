#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/application.t - application tests
#
# ==============================================================================  

use Test::More tests => 5;
use warnings;
use strict;

my $app;

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Application");
}

# methods
ok( Eidolon::Application->can("start"),          "start method"          );
ok( Eidolon::Application->can("handle_request"), "handle_request method" );

$app = Eidolon::Application->new;

# application types
is( $app->TYPE_CGI,  0, "CGI application type"  );
is( $app->TYPE_FCGI, 1, "FCGI application type" );

