# -*-perl-*-
#
# test renaming namespaces
#

use strict;

use Test::More tests => 7;

## Tests

use Inline 'SLang' => Config =>
	BIND_NS => [ "Global=foo", "foo=bar" ],
	BIND_SLFUNCS => [ "get_struct_field_names", "get_struct_field=gsf" ];
use Inline 'SLang' => <<'EOS1';

define fn_in_global(x) { "in global"; }

implements( "foo" );

define fn_in_foo(x) { "in foo"; }

EOS1

is( foo::fn_in_global("dummy"), "in global",
    "Can call fn_in_global() as foo::fn_in_global()" );

is( bar::fn_in_foo("dummy"), "in foo",
    "Can call foo->fn_in_fn() as bar::fn_in_global()" );

# safety check
eval "print fn_in_global(1);";
like( $@, qr/^Undefined subroutine &main::fn_in_global called at /,
      "Can not call fn_in_global() as fn_in_global()" );

my $struct = Struct_Type->new( ["aa", "bb"] );
$$struct{aa} = 23;
$$struct{bb} = "a string";

# check we can use the S-Lang intrinsic functions
ok( eq_array( foo::get_struct_field_names($struct), ["aa","bb"] ),
    "Can call get_struct_field_names() as foo::get_struct_field_names()" );

is( foo::gsf($struct,"aa"), 23,
    "Can call get_struct_field() as foo::gsf()" );

# since the function isn't available it doesn't matter what arguments I
# send it ;)
# note the optional main:: in the first error message; I don't know why
# it's needed, so I've made it optional
# perhaps it's indicative of a subtle error in the binding code?
eval "foo::get_struct_field();";
like( $@, qr/^Undefined subroutine &(main::)?foo::get_struct_field called at /,
      "foo::get_struct_field() is unknown" );
eval "get_struct_field();";
like( $@, qr/^Undefined subroutine &main::get_struct_field called at /,
      "get_struct_field() is unknown" );

## End

