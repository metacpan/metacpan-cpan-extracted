#!perl

use Test::More;
use Test::Exception;

use warnings;
use strict;

use JSPL qw(:primitives);

if(JS_NULL) {
    plan tests => 11;
} else {
    plan skip_all => "null handling not implemented yet";
}
# Null it's a primitive type and null it's a primitive value of that type.
is(JS_NULL, JSPL::Null->Null(), "Type and value are defined");


my $ctx = JSPL->stock_context;
my $null = $ctx->eval("null"); # Get a JS null object;

isa_ok($null, "JSPL::Null");
isa_ok($null, "JSPL::Object");

is(0, scalar keys %$null, "null is empty");
throws_ok
    { $null->{foo} = 10; }
    qr/TypeError: \w+ has no properties/,
    "nulls can't be extended"; 


ok(!$null, "null is false");
is(0 + $null, 0, "null is 0");
is("" + $null, "null", "null is the string 'null'");

# 11.9.3
is($null, $null, "null == null");
is($null, undef, "null == undefined");

# 15.5.4.10  String.prototype.match (can return nulls)
my $null_match = $ctx->eval('"123".match(/abc/);');
is($null_match, JS_NULL, "match can return null");

# 15.10.6.2  RegExp.prototype.exec  (can return nulls)
my $null_match2 = $ctx->eval('/abc/.exec("123");');
is($null_match2, JS_NULL, "exec can return null");
