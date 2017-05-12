#!/usr/bin/perl
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   t/debug.t - debugging tests
#
# ==============================================================================  

use Test::More tests => 8;
use warnings;
use strict;

# should use "use_ok" instead, but it hooks die handler and overrides ours, so 
# die handler test will fail
eval
{
    use Eidolon::Debug; 
};

# error check
ok( !$@, "use Eidolon::Debug" );

# methods
ok( Eidolon::Debug->can("start_console"), "start_console method" );
ok( Eidolon::Debug->can("get_stack"),     "get_stack method"     );
ok( Eidolon::Debug->can("print_stack"),   "print_stack method"   );
ok( Eidolon::Debug->can("warn"),          "warn method"          );
ok( Eidolon::Debug->can("die"),           "die method"           );

# error and warning handlers
is( $SIG{"__DIE__"},  \&Eidolon::Debug::die,  "error handler"    );
is( $SIG{"__WARN__"}, \&Eidolon::Debug::warn, "warning handler"  );

