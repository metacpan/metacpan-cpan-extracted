#
# test binding functions
# - earlier tests have implivitly tested the 
#     BIND_NS => [ "Global" ] 
#   option
#

use strict;

use Test::More tests => 2;

## Tests

use Inline 'SLang' => Config => BIND_NS => [ "foo" ];
use Inline 'SLang' => <<'EOS1';

define fn_in_global(x) { "in global"; }

implements( "foo" );

define fn_in_foo(x) { "in foo"; }

EOS1

# could inspect the symbol table directly but I can't
# be bothered to find out how
#
eval "print fn_in_global(1);";
like( $@, qr/^Undefined subroutine &main::fn_in_global called at /,
   "Can not call Global->fn_in_global() as fn_in_global()" );

is( foo::fn_in_foo("dummy"), "in foo",
    "Can call foo->fn_in_foo() as foo::fn_in_foo()" );

## End

