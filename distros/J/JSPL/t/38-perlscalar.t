#!perl
use Test::More tests => 199;  # last test to print
use strict;

use JSPL;

my $LoDo;
use Config;
BEGIN {
    if($Config{uselongdouble} &&
       $Config{doublesize} != $Config{longdblsize})
    {
	$LoDo = 1; # Expect some precision lost
    }
}
use warnings;

my $ctx = JSPL->stock_context;
$ctx->bind_all(
    ok => \&ok, is => \&is,
    dr => sub { ${$_[0]} }, 
    rt => sub {
	my($r, $dr) = @_;
	ok(JSPL::Context::current->jsvisitor($r), "A visitor");
	is($$r, $dr, "The same thing ($dr), perl side")
	    if defined $dr;
    }
);

my($obj, $arr, $is_scalar) = @{$ctx->eval(q|[
    { v:'a' }, 
    [ 2, 3 ], 
    function (v, like, typ, pt) {
	ok(v instanceof PerlScalar, "Is a PerlScalar");
	is(v.valueOf(), like, "Is like "+like);
	is(typeof v.valueOf(), typ, "Its type is " + typ);
	ok(v.valueOf() === dr(v), "The exact same thing, js side");
	rt(v, dr(v));
	var nr = new PerlScalar(like);
	ok(dr(v) === dr(nr), "Can contruct one");
    }
];|)};
isa_ok($obj, 'HASH');
isa_ok($arr, 'ARRAY');
isa_ok($is_scalar, 'JSPL::Function');

$is_scalar->(\"foo", "foo", 'string');
$is_scalar->(\1000, 1000, 'number');
my $foo;
$is_scalar->(\$foo, $foo, 'undefined');
$foo = "foo";
$is_scalar->(\$foo, $foo, 'string');
$foo = 1000;
$is_scalar->(\$foo, $foo, 'number');
$foo = $LoDo ? 0.0 : 3.14159265;
$is_scalar->(\$foo, $foo, 'number');
$foo = \"foo";
$is_scalar->(\$foo, $foo, 'object');
$is_scalar->(\\$foo, \$foo, 'object');
$foo = [1, 2];
$is_scalar->(\$foo, $foo, 'object');
$is_scalar->(\\$foo, \$foo, 'object');
$foo = {k=>'val'};
$is_scalar->(\$foo, $foo, 'object');
$is_scalar->(\\$foo, \$foo, 'object');
$foo = bless {};
$is_scalar->(\$foo, $foo, 'object');
$is_scalar->(\\$foo, \$foo, 'object');
$foo = sub {};
$is_scalar->(\$foo, $foo, JSPL::get_internal_version() < 185
    ? 'object' : 'function');
$is_scalar->(\\$foo, \$foo, 'object');
# Test Javascript natives
$foo = $obj;
$is_scalar->(\$foo, $foo, 'object');
$is_scalar->(\\$foo, \$foo, 'object');
$foo = tied(%$obj);
{ local $ctx->{AutoTie} = 0;
$is_scalar->(\$foo, $foo, 'object');
}
$is_scalar->(\\$foo, \$foo, 'object');
$foo = $arr;
$is_scalar->(\$foo, $foo, 'object');
$is_scalar->(\\$foo, \$foo, 'object');
$foo = tied(@$arr);
{ local $ctx->{AutoTie} = 0;
$is_scalar->(\$foo, $foo, 'object');
}
$is_scalar->(\\$foo, \$foo, 'object');
#$foo = $is_scalar;
#$is_scalar->(\$foo, $foo, 'function');
$is_scalar->(\$is_scalar, $is_scalar, 'function');
$is_scalar->(\\$foo, \$foo, 'object');
$foo = $ctx->get_global;
$is_scalar->(\$foo, $foo, 'object');
$is_scalar->(\\$foo, \$foo, 'object');

ok(1, "All done");

