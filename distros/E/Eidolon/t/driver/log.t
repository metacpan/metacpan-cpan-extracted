#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/driver/log.t - generic log driver tests
#
# ==============================================================================  

use Test::More tests => 7;
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
}

# methods
ok( Eidolon::Driver::Log->can("open"),    "open method"    );
ok( Eidolon::Driver::Log->can("close"),   "close method"   );
ok( Eidolon::Driver::Log->can("notice"),  "notice method"  );
ok( Eidolon::Driver::Log->can("warning"), "warning method" );
ok( Eidolon::Driver::Log->can("error"),   "error method"   );

