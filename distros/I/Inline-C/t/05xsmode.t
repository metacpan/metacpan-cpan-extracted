use strict; use warnings; use diagnostics;
use FindBin '$Bin';
use lib $Bin;
use Test::More;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

use Inline C => DATA => ENABLE => XSMODE => NAME => 'xsmode';

is(add(5, 10), 15);
done_testing;

__END__

__C__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = xsmode      PACKAGE = main

int
add (x, y)
        int     x
        int     y
    CODE:
        RETVAL = x + y;
    OUTPUT:
        RETVAL
