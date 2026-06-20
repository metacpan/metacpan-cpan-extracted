use strict;
use warnings;
use Test::More;
use Destructure::Declare;

# basic by-key binding from a hashref
let {name => $n, age => $a} = {name => 'Ann', age => 30};
is($n, 'Ann', 'name');
is($a, 30,    'age');

# bareword and quoted keys
let {"first name" => $f, last => $l} = {'first name' => 'Jo', last => 'Bloggs'};
is($f, 'Jo',     'quoted key');
is($l, 'Bloggs', 'bareword key');

# missing key -> undef
{
	no warnings 'uninitialized';
	let {nope => $z} = {};
	ok(!defined $z, 'missing key undef');
}

# only the requested keys are bound; others ignored
let {wanted => $w} = {wanted => 1, ignored => 2};
is($w, 1, 'unrequested keys ignored');

# empty hash pattern
let {} = {a => 1};
ok(1, 'empty hash pattern ok');

done_testing;
