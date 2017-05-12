# -*-perl-*-
#
# test binding functions: BIND_NS => "All"
#

use strict;

use Test::More tests => 2;

## Tests

my $use_ns;

use Inline 'SLang' => Config => BIND_NS => "All";
use Inline 'SLang' => <<'EOS1';

define fn_in_global(x) { "in global"; }

implements( "foo" );

define fn_in_foo(x) { "in foo"; }

EOS1

is( fn_in_global(1), "in global",
  "Can call fn_in_global() as fn_in_global()" );

is( foo::fn_in_foo("dummy"), "in foo",
  "Can call foo->fn_in_foo() as foo::fn_in_foo()" );

## End

