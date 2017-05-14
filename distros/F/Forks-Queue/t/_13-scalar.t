use Test::More;
use Carp 'verbose';
use Net::Objwrap ':all-test';
use 5.012;
use Scalar::Util 'reftype';

my $wrap_cfg = 't/13.cfg';
unlink $wrap_cfg;

my $foo = "42";
my $r0 = bless \$foo, 'ScalarThing';

ok($r0 && ref($r0) eq 'ScalarThing', 'created remote var');
ok(! -f $wrap_cfg, 'config file does not exist yet');

ok(wrap($wrap_cfg,$r0), 'wrap successful');
ok(-f $wrap_cfg, 'config file created');

my $r1 = unwrap($wrap_cfg);
ok($r1, 'client as boolean');
ok(ref($r1) eq 'Net::Objwrap::ProxyS', 'proxy ref');

ok(Net::Objwrap::ref($r1) eq 'ScalarThing', 'remote ref');
ok(Net::Objwrap::reftype($r1) eq 'SCALAR', 'remote reftype');

is($$r1, "42", "scalar access");

${$r1} = 456;
is($$r1, 456, 'update scalar');

$$r1 += 15;
is($$r1, 471, 'update scalar with assignment operator');

is(eval { $r1->hello }, 'hello', 'remote method call of SCALAR obj');

done_testing;



sub ScalarThing::hello {
    return "hello";
}



