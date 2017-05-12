#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/main.t - basic log driver tests
#
# ==============================================================================  

use Test::More tests => 8;
use warnings;
use strict;

# ------------------------------------------------------------------------------
# BEGIN()
# test initialization
# ------------------------------------------------------------------------------
BEGIN
{
    use_ok("Eidolon::Driver::Exceptions");
    use_ok("Eidolon::Driver::Log");
    use_ok("Eidolon::Driver::Log::Basic");
}

# methods
ok( Eidolon::Driver::Log::Basic->can("open"),    "open method"    );
ok( Eidolon::Driver::Log::Basic->can("close"),   "close method"   );
ok( Eidolon::Driver::Log::Basic->can("notice"),  "notice method"  );
ok( Eidolon::Driver::Log::Basic->can("warning"), "warning method" );
ok( Eidolon::Driver::Log::Basic->can("error"),   "error method"   );

