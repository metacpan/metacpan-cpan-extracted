#!perl
use strict;
use warnings;

use Test::More;

use JSPL;
use JSPL::Context::Timeout;

if($^O eq 'MSWin32') {
    plan skip_all => "Timeout not implemented in MSWin32";
} else {
    plan tests => 13;
}

my $ctx = JSPL::Runtime->new->create_context;

$ctx->eval(q|
    var foo;
    function large() {
	foo = 0;
	while(foo < 10000000) {
	    foo++;
	}
	return foo;
    }
|);

$ctx->set_timeout(0.2);
ok(!defined(eval {
    $ctx->eval_wto(q| large() |);
}), "Undefined");

ok($@, "Interrupted");
like($@, qr/Operation timeout/, 'Timeout');
my $foo = $ctx->eval('foo');
diag("Iterations: $foo");

my $pass = 0;
$ctx->set_timeout(0.1, sub {
    $pass++, 
    ok(1, 'In callback');
    return 0; # Signal terminate
});

ok(!defined($ctx->eval_wto(q| large() |)), "Undefined");

ok($pass, "Returned");
ok(!$@, 'without errors');

$ctx->set_timeout(0.1, sub {
    ok(1, 'In callback');
    return ++$pass < 4 ? 0.1 : undef;
});

ok(!defined($ctx->eval_wto(q| large() |)), "Undefined");

is($pass, 4, "Four tries");
ok(!$@, 'without errors');
