#!perl
use strict;
use warnings;
use utf8;

use Test::More tests => 36;

use JSPL;

use Scalar::Util qw(reftype);
use B qw(svref_2object);

# JavaScript emulation
sub JSPL::PerlHash::new { bless {}, 'JSPL::PerlHash' }
sub JSPL::PerlHash::get_ref { $_[0]; }
$JSPL::PerlHash::construct_blessed = 1;

my $rt = JSPL::Runtime->new();
my $cx = $rt->create_context();
$cx->bind_function(ok => \&ok);

ok($JSPL::PerlHash::construct_blessed, "In legacy mode");
{
    my $hash = JSPL::PerlHash->new();
    ok(defined $hash, "Defined");
    isa_ok($hash, "JSPL::PerlHash");
    ok(my $hv = $hash->get_ref, "Can get ref");
    is(reftype $hv, "HASH", "Reference is Hash");
    is_deeply($hash->get_ref, {}, "Empty");
}

{
    my $hash = $cx->eval(q/
        var hash = new PerlHash('foo', 2);
        ok(hash instanceof PerlHash, "instanceof");
        hash;
/);

    isa_ok($hash, "JSPL::PerlHash", "Legacy wrapper");
    is_deeply($hash->get_ref, {foo => 2}, "Loaded");
}

{
    my $hash = JSPL::PerlHash->new();

    $hash->get_ref->{a} = 10;
    $hash->get_ref->{b} = 20;
    
    $cx->eval(q/
        function check_perlhash(hash) {
            ok(hash instanceof PerlHash, "Instance");
            ok(hash.a == 10 && hash.b == 20, "As setted");

            hash.c = 40;
            hash.b += hash.a;
	    ok(hash.b == 30 && hash.c == 40, "Values stored");
	}
/);
    $cx->call(check_perlhash => $hash);
    ok($hash->get_ref->{b} == 30 && $hash->get_ref->{c} == 40, "Modified");
    is_deeply($hash->get_ref, {a=>10, b=>30, c=>40}, "As expected");
}

# Ok, Turns off legacy mode
$JSPL::PerlHash::construct_blessed = undef;
{
    my $hash = $cx->eval(q/
        function check_hash(hash) {
            ok(hash instanceof PerlHash, "Unicode Instance");
	    var items = 0;
	    for(var item in hash) {
		items++;
		if(hash[item] == 1) ok(item == "\251", "got &copy;");
		if(hash[item] == 2) ok(item == "\xe9", "got e-acute");
		if(hash[item] == 3) ok(item == "\u2668", "got hot strings");
	    }
	    ok(items == 3, "Has 3 items");
        }

	hash = new PerlHash(
	    "\251", 1,
	    "\xe9", 2,
	    "\u2668", 1+2
	);

        ok(hash instanceof PerlHash, "instanceof");
	hash;
/);
    isa_ok($hash, 'HASH', "A simple perl hash");

    my $eqhash = {"\x{a9}" => 1, 'é' => 2, "\x{2668}" => 3};
    $cx->call(check_hash => $hash);
    $cx->call(check_hash => $eqhash);
    is_deeply($hash, $eqhash, "Looks the same");
}

# Test refcounting
is($cx->eval('hash')->{"\x{a9}"} + $cx->eval('hash')->{"é"},
    $cx->eval('hash')->{"\x{2668}"}++, "Not in scope but alive");

my($sv, $ref);
{
    my $hash = $cx->eval('hash');
    ok(ref($hash) eq 'HASH' && $hash->{"\x{2668}"} == 4, "Its it");
    $sv = svref_2object($hash);
    is($sv->REFCNT, 2, "RC 2, alive in both sides");
    my @a = ($hash) x 100;
    is($sv->REFCNT, 102, "A lot more");
    $ref = $hash;
}
is($sv->REFCNT, 2, "RC 2");
$ref = undef;
is($sv->REFCNT, 1, "Only alive in JS side");
$cx->eval('hash2 = hash;');
is($sv->REFCNT, 1, "JS side only owns 1");
$cx->eval('hash = undefined');
is($sv->REFCNT, 1, "Still alive");
$cx->eval('hash2 = undefined');
is($sv->REFCNT, 0, "Has gone");
