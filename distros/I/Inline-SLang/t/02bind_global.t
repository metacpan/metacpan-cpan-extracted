#
# test binding functions
# - earlier tests have implicitly tested the 
#     BIND_NS => [ "Global" ] 
#   option
#

use strict;

use Test::More tests => 3;

## Tests

use Inline 'SLang' => Config => BIND_NS => "Global";
use Inline 'SLang' => <<'EOS1';

define fn_in_global(x) { "in global"; }

implements( "foo" );

define fn_in_foo(x) { "in foo"; }

EOS1

is( fn_in_global("dummy"), "in global",
  "Can call fn_in_global() as fn_in_global()" );

# could inspect the symbol table directly but I can't
# be bothered to find out how
#
eval "print foo::fn_in_foo(1);";
like( $@, qr/^Undefined subroutine &foo::fn_in_foo called at /,
   "and can not call foo->fn_in_foo() as foo::fn_in_foo()" );

# also check we haven't bound a random S-Lang intrinsic
#
eval "array_info();";
like( $@, qr/^Undefined subroutine &main::array_info called at /,
   "and can not call S-Lang intrinsic array_info()" );

## End

