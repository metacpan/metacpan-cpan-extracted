#!perl

use Test::More tests => 39;
use Test::Exception;

use strict;
use warnings;

use JSPL;

ok( my $rt1 = JSPL::Runtime->new(), "created runtime" );
{
ok( my $cx1 = $rt1->create_context(), "created context" );

$cx1->bind_all(ok => \&ok, is => \&is);

{
    ok($cx1->bind_function(
	name => 'test',
	func => sub {
	    my $rv = $_[0]->();
	    ok($rv, $rv);
	    $rv
	}
       ),
       "bound function"
   );
}

my $code = <<'EOC';

function perl_apply() {
    var args = new Array()
    for (var i = 0; i < arguments.length; i++) {
        args.push(arguments[i]);
    }

    var func = args.shift();
    return func.apply(undefined, args);
}

function testFunc() {
    return "called test function from perl space okay";
}

function checkName(fun, name) {
    ok(fun instanceof PerlSub, "A PerlSub");
    ok(fun.name == name, "Correct name");
    return fun.name;
}

function checkContext(fun) {
    ok(fun.$wantarray, "Default ok");
    is(fun(), "array", "Returns array");
    ok(fun(1) instanceof PerlArray, "Returns many");
    fun.$wantarray = false;
    is(fun(), "scalar", "Returns scalar");
    var r = fun(1);
    is(typeof r, 'number', "Returns a scalar");
    is(r, 1, "Returns last (as expected)");
    fun.$wantarray = true;
    is(fun(1)[1], 2, "List again");
    return fun.$wantarray;
}

test( testFunc );
// testFunc();

EOC

ok( my $rv = $cx1->eval( $code ), "eval'd code" );
is( $rv, "called test function from perl space okay", "roundtrip");

# Test basic PerlSub properties
is( $cx1->eval('test instanceof PerlSub;'), 1, "Instace of PerlSub");
is( $cx1->call(checkName => \&is, 'is'), 'is', "PerlSubs have names");
is( $cx1->eval('test.name'), '(anonymous)', "Anonymous too");

# Test calling context handling
ok( $cx1->call(checkContext => sub {
    return (3, 2, 1) if($_[0]);
    wantarray ? 'array' : 'scalar';
}), "Calling context works");

eval "use List::Util";
skip ("List::Util is not installed", 1) if $@;
no warnings 'once';
is ($cx1->call('perl_apply',
	sub {
	    return List::Util::reduce { $a + $b } @_ 
	}, 1, 2, 3, 4),
    10, 'invoke perlsub from javascript');

{
    $cx1->bind_function(testapply => sub {
	return $JSPL::This;
    });

    my $result = $cx1->eval(q!testapply.apply({ test: 1 }, []);!);
    is_deeply( $result, { test => 1}, "test that apply does what it does in JS");
}

# Test that can construct PerlSubs from javascript
{
    local $cx1->{Restricted} = 0; # Allow JS land to use PerlSub constructor
    ok(my $cref = $cx1->eval(q|
	var code = new PerlSub("\
	    ok(scalar(@_) == 1, 'Args count');\
	    ok($_[0] eq 'foo','Called with arg foo');\
	    is(__PACKAGE__, 'main', 'In correct package');\
	    return 'bar' ");
	code;
    |), "Code created");
    isa_ok($cref, 'CODE');
    is( $cx1->eval(' code("foo") '), 'bar', "Can be used" );
    is( $cref->('foo'), 'bar', "From perl too");
    is( $cx1->eval(q| (new PerlSub("'foo'"))() |), 'foo', "Can construct simple");

    SKIP: {
      skip "Perl > 5.9 needed for propagated strictures", 2 unless $] > 5.009; 
      use strict 'subs';
      throws_ok { $cx1->eval(q| new PerlSub("biz") |) } 
	qr/Bareword "biz" not allowed/, "Bareword not allowed with strict subs";
      no strict 'subs';
      no warnings 'reserved';
      lives_ok { $cx1->eval(q| new PerlSub("biz") |) } "Bareword now allowed";
    }

    throws_ok { $cx1->eval(q| new PerlSub() |) } qr/requires more/,
	"Needs arg";

    throws_ok { $cx1->eval(q| new PerlSub("}{") |) } qr/Can't compile/,
	'Syntax error';

    throws_ok {  $cx1->eval(q| (new PerlSub("die 'foo'"))() |) } qr/foo/,
	"Runtime error";
}

# Now not allowed
throws_ok { $cx1->eval(q| new PerlSub("'bar'") |) } qr/Not enough privileges/,
    "Restricted";

}

ok(1, "All done, clean");

