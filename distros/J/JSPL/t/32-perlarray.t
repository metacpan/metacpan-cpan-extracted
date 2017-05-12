#!perl
use strict;
use warnings;

use Test::More tests => 66;

use JSPL;

use Scalar::Util qw(reftype);
use B qw(svref_2object);

# Claes compatibility
sub JSPL::PerlArray::new { bless [], 'JSPL::PerlArray' }
sub JSPL::PerlArray::get_ref { $_[0] }
$JSPL::PerlArray::construct_blessed = 1; # Turn on legacy mode

my $cx = JSPL->stock_context;
$cx->bind_all(ok => \&ok, is => \&is);

{
    my $arr = JSPL::PerlArray->new();
    ok(defined $arr);
    isa_ok($arr, "JSPL::PerlArray");
    ok($arr->get_ref);
    my $av = $arr->get_ref;
    is(reftype $av, "ARRAY");
    is_deeply($arr->get_ref, []);
}

{
    my $arr = $cx->eval(q/
        var array = new PerlArray();
        ok(array instanceof PerlArray, 'Instance');
        array;
    /);

    isa_ok($arr, "JSPL::PerlArray");
    is_deeply($arr->get_ref, [], "Empty");
}

{
    my $arr = JSPL::PerlArray->new();

    push @{$arr->get_ref}, 10, 20, 30;

    $cx->eval(q/
        function check_perlarray(arr) {
            ok(arr instanceof PerlArray, "Instance");
            is(arr.length, 3, "Length");
            ok(arr[0] == 10, "Get at 0");
            ok(arr[1] == 20);
            ok(arr[2] == 30);
            ok(arr[-1] == 30, "Get at end");
        }
/);

    $cx->call(check_perlarray => $arr);
}

{
    $cx->eval(q| ok((new PerlArray()) instanceof PerlArray, 'Instance') |);
}

{
    $cx->eval(q/
        var array = new PerlArray();
        
        array.push(10);
        ok(array.length == 1);
        ok(array[0] == 10);
        
        array.unshift(20, 30);
        ok(array.length == 3);
        ok(array[0] == 20 && array[1] == 30 && array[2] == 10);
        
        ok(array.shift() == 20);
        ok(array.length == 2);
        
        ok(array.pop() == 10);
        ok(array.length == 1);
    /)
}

{
    my $arr = JSPL::PerlArray->new();
    $cx->eval(q/
        function populate_perlarray_via_index(array) {
            array[2] = 20;
        }
    /);
    is_deeply($arr->get_ref, []);
    $cx->call(populate_perlarray_via_index => $arr);
    is_deeply($arr->get_ref, [undef, undef, 20]);
}

# Turns off legacy compatibility mode
$JSPL::PerlArray::construct_blessed = undef;

{
    my $arr = [10, 20, 30];
    $cx->call(check_perlarray => $arr);
    ok($arr=$cx->eval(q| array = new PerlArray(7, 6, 5, 4, 3, 2, 1); array |),
	"Constructed");
    isa_ok($arr, 'ARRAY', "A simple ARRAY");
    ok(!tied(@$arr), "A real one");
    is_deeply($arr, [7, 6, 5, 4, 3, 2, 1], "Looks good");
    $cx->eval(q| populate_perlarray_via_index(array); |);
    is($arr->[2], 20, "Changes reflected");
    $cx->eval(q|
	is(array.join(), "7,6,20,4,3,2,1", "Inheritance from Array works");
	array[2] = ['foo','bar'];
	is(array.toSource(), 'new PerlArray(7,6,["foo", "bar"],4,3,2,1)', "Hibrid");
    |);
}

# Test refcounting
is($cx->eval('array')->[-1] + $cx->eval('array')->[-2], $cx->eval('array')->[-3],
    "Not in scope but alive");

my($sv, $ref);
{
    my $arr = $cx->eval('array');
    ok(ref($arr) eq 'ARRAY' && $arr->[0] == 7, "Its it");
    $sv = svref_2object($arr);
    is($sv->REFCNT, 2,  "RC 2,  alive in both side");
    my @a = ($arr) x 100;
    is($sv->REFCNT, 102,  "A lot more");
    $ref = $arr;
}

is($sv->REFCNT, 2,  "RC 2");
$ref = undef;
is($sv->REFCNT, 1, "Only alive in JS side");

# Test caching
{
    my @a = ();
    for(my $c = 0; $c < 100; $c++) {
	push @a, $cx->eval('array');
    }
    is($sv->REFCNT, 101, "A lot of copies");
    undef @a;
    is($sv->REFCNT, 1, "Now only in JS");
}

ok($cx->eval('array2 = array; array2 === array'), "A copy");
is($sv->REFCNT, 1, "JS side only owns one reference");
ok($cx->eval('array = undefined; typeof array == "undefined";'), "'array' gone");
is($sv->REFCNT, 1, "Still alive");

my $sv2;
{
    my $sentinel = bless {}, 'Traker';
    $sv2 = svref_2object($sentinel);
    is($sv2->REFCNT, 1, "A new sentinel");
    my $jsobj;
    {
	ok(my $jsarr = $cx->eval('array2[2]'), 'Get js array');
	is(ref($jsarr), 'ARRAY', 'Looks like ARRAY');
	ok($jsobj = tied(@$jsarr), 'Is tied');
    }
    isa_ok($jsobj, "JSPL::Array", 'Is a Array'); 
    bless $jsobj, ref($jsobj) if $] < 5.009; # With 5.8 the previous test pass, but
					     # oveload missing, need re-bless
    is($jsobj->[1], 'bar', 'Expected');
    $jsobj->[1] = $sentinel;
    undef $jsobj;
    is($sv2->REFCNT, 2, "Sentinel alive");
    is($cx->eval('array2[2][1].__PACKAGE__'), 'Traker', 'Sentinel in JS side');
    undef $sentinel;
    is($sv->REFCNT, 1, "Sentinel installed");
}

is($sv2->REFCNT, 1, "Can track the sentinel");
is($cx->eval('bury = {}; bury.deep = {}; bury.deep.scope = array2[2][1]; undefined'),
    undef, "Dont want leak to perl");

$cx->eval('delete array2;');
is($sv->REFCNT, 0, "Array has gone");

is($sv2->REFCNT, 1, "Sentinel deep in context");

my $ctxalive = 1;
$cx = undef;
is($sv2->REFCNT, 0, "Gone with context");

is($ctxalive,  0, "Context gone");
ok(1, "All right, done");

sub Traker::DESTROY {
    diag("Context destroyed");
    $ctxalive--;
}
