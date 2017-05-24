use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Test::More;
use Data::Dumper;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

$js->set( pass => \&Test::More::pass );

$js->eval(q{
    function TEST(o){
        if ( o.a.x.x === o ) pass('nested object pass');
        if ( o.a.x.x.arr === o.a.x.x.arr[1] ) pass('nested array pass');
        if ( o.a.x.x.arr[0] === o ) pass('nested array objects pass');
        return o.a.x.x;
    }
});

my $obj = { a => {}, b => 9, num => 9 };
my $obj2 = { x => $obj };
$obj->{a}->{x} = $obj2;
$obj->{b} = {
    sub => sub { ok 1; }
};

my $arr = [$obj];
$arr->[1] = $arr;

$obj2->{x}->{arr} = $arr;

$duk->push_perl($obj);

$duk->eval_string('TEST');
$duk->dup(1);
$duk->call(1);

my $retObject = $duk->to_perl(-1);

ok ref $retObject->{b}->{sub} eq 'CODE';
is $retObject->{num}, 9;
is $retObject->{arr}->[0], $retObject;
is $retObject->{arr}, $retObject->{arr}->[1];

done_testing(7);
