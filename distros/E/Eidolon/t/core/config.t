#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/core/config.t - configuration tests
#
# ==============================================================================  

use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More tests => 15;
use ETests_Config;
use warnings;
use strict;

my $cfg;

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Core::Config");
}

$cfg = Eidolon::Core::Config->new( "ETests_Config", 0 );

is( $Eidolon::Core::Config::INSTANCE, $cfg, "Object instance" );

# application configuration tests
is( $cfg->{"app"}->{"title"},   undef,                    "application title"  );
is( $cfg->{"app"}->{"name"},    "ETests_Config",         "application name"   );
is( $cfg->{"app"}->{"version"}, $ETests_Config::VERSION, "application version" );
is( $cfg->{"app"}->{"root"},    $FindBin::Bin,            "application root"   );
is( $cfg->{"app"}->{"type"},    0,                        "application type"   );
is( $cfg->{"app"}->{"policy"},  "private",                "application policy" );

is_deeply
( 
    $cfg->{"app"}->{"error"}, 
    [ "Eidolon::Error", "error" ],
    "application error handler"
);

# CGI configuration tests
is( $cfg->{"cgi"}->{"max_post_size"},  600000,      "CGI max POST size"       );
is( $cfg->{"cgi"}->{"tmp_dir"},        "/tmp/",     "CGI temporary directory" );
is( $cfg->{"cgi"}->{"charset"},        "UTF-8",     "CGI charset"             );
is( $cfg->{"cgi"}->{"content_type"},   "text/html", "CGI content type"        );
is( $cfg->{"cgi"}->{"session_cookie"}, "SESSIONID", "CGI session cookie name" );

# drivers configuration tests
ok( defined $cfg->{"drivers"}, "drivers list" );

