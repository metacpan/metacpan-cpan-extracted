use strict;
use warnings;

use Test::More tests => 3;

BEGIN { use_ok( 'KinoSearch1', 'K_DEBUG' ) }

ok( !K_DEBUG, "DEBUG mode should be disabled" );
ok( !KinoSearch1::memory_debugging_enabled(),
    "Memory debugging should be disabled"
);

