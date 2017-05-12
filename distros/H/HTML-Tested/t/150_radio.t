use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;
use Data::Dumper;
use Carp;

BEGIN { use_ok('HTML::Tested', qw(HTV)); 
	use_ok('HTML::Tested::Test'); 
	use_ok('HTML::Tested::Value::Radio');
	use_ok('HTML::Tested::List');
}

my $_id = 1;

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV.'::Radio', 'v', default_value => [ 'a', 'b', 'c' ]);

package main;

my $object = T->new;
is($object->v, undef);

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v_a => <<ENDS
<input type="radio" name="v" id="v" value="a" />
ENDS
, v_b => <<ENDS
<input type="radio" name="v" id="v" value="b" />
ENDS
, v_c => <<ENDS
<input type="radio" name="v" id="v" value="c" />
ENDS
, }) or diag(Dumper($stash));

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, {}) ], []);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { v => [ 'a', 'b', 'c' ] }) ], []);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { v => [ 'a', [ 'b', 1 ], 'c' ] }) ], [
'Mismatch at v_b: got "<input type="radio" name="v" id="v" value="b" />
", expected "<input type="radio" name="v" id="v" value="b" checked />
"'
]);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { v => [ 'a', 'b' ] }) ], [
'Mismatch at v_c: got "<input type="radio" name="v" id="v" value="c" />
", expected undef'
]);

delete $stash->{v_c};
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { v => [ 'a', 'b', 'c' ] }) ], [
'Mismatch at v_c: got undef, expected "<input type="radio" name="v" id="v" value="c" />
"'
]);

$object->v([ 'a', [ 'b', 1 ], 'c' ]);
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v_a => <<ENDS
<input type="radio" name="v" id="v" value="a" />
ENDS
, v_b => <<ENDS
<input type="radio" name="v" id="v" value="b" checked />
ENDS
, v_c => <<ENDS
<input type="radio" name="v" id="v" value="c" />
ENDS
, }) or diag(Dumper($stash));

is_deeply([ HTML::Tested::Test->check_text(ref($object), <<ENDS
<input type="radio" name="v" id="v" value="a" />
<input type="radio" name="v" id="v" value="b" checked />
<input type="radio" name="v" id="v" value="c" />
ENDS
	, { v => [ 'a', [ 'b', 1 ], 'c' ] }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object), <<ENDS
<input type="radio" name="v" id="v" value="a" />
<input type="radio" name="v" id="v" value="b" checked />
<input type="radio" name="v" id="v" value="c" />
ENDS
	, { v => [ 'a', [ 'b', 1 ], [ 'c', 1 ] ] }) ], [
'Unable to find "<input type="radio" name="v" id="v" value="c" checked />
" in "<input type="radio" name="v" id="v" value="a" />
<input type="radio" name="v" id="v" value="b" checked />
<input type="radio" name="v" id="v" value="c" />
"'
]);


package L;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::List', 'l1', 'T');

package main;

$object = L->new({ l1 => [ map { T->new({ v => $_ }) }
				[ [ 'a', 1 ], 'b', 'c' ]
				, [ 'a', 'b', [ 'c', 1 ] ] ] });
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { l1 => [ { v_a => <<ENDS
<input type="radio" name="l1__1__v" id="v" value="a" checked />
ENDS
, v_b => <<ENDS
<input type="radio" name="l1__1__v" id="v" value="b" />
ENDS
, v_c => <<ENDS
<input type="radio" name="l1__1__v" id="v" value="c" />
ENDS
}, { v_a => <<ENDS
<input type="radio" name="l1__2__v" id="v" value="a" />
ENDS
, v_b => <<ENDS
<input type="radio" name="l1__2__v" id="v" value="b" />
ENDS
, v_c => <<ENDS
<input type="radio" name="l1__2__v" id="v" value="c" checked />
ENDS
} ], }) or diag(Dumper($stash));

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
	{ l1 => [ { v => [ [ 'a', 1 ], 'b', 'c' ] }, 
		{ v => [ 'a', 'b', [ 'c', 1 ] ] } ] }) ], []);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
	{ l1 => [ { }, 
		{ v => [ 'a', 'b', [ 'c', 1 ] ] } ] }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object), <<ENDS
<input type="radio" name="l1__1__v" id="v" value="a" checked />
<input type="radio" name="l1__1__v" id="v" value="b" />
<input type="radio" name="l1__1__v" id="v" value="c" />
<input type="radio" name="l1__2__v" id="v" value="a" />
<input type="radio" name="l1__2__v" id="v" value="b" />
<input type="radio" name="l1__2__v" id="v" value="c" checked />
ENDS
	, { l1 => [ { v => [ [ 'a', 1 ], 'b', 'c' ] }, 
		{ v => [ 'a', 'b', [ 'c', 1 ] ] } ] }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object), <<ENDS
<input type="radio" name="l1__1__v" id="v" value="a" checked />
<input type="radio" name="l1__1__v" id="v" value="b" />
<input type="radio" name="l1__1__v" id="v" value="c" />
ENDS
	, { l1 => [ { v => [ [ 'a', 1 ], 'b', 'c' ] }, 
		{ } ] }) ], []);

my $_def_val = [ 'a', [ 'b', 1 ] ];

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV.'::Radio', 'v', default_value => $_def_val);

package main;

$object = T2->new;

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v_a => <<ENDS
<input type="radio" name="v" id="v" value="a" />
ENDS
, v_b => <<ENDS
<input type="radio" name="v" id="v" value="b" checked />
ENDS
});
is_deeply($_def_val, [ 'a', [ 'b', 1 ] ]);


package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, 'v');

package main;
$object = T3->new({ v => "a\nb\nc\n" });;
$object->ht_render($stash);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { v => "a\nc\n" }) ], [ 'Mismatch at v: got "a
b
c
", expected "a
c
". The diff is
@@ -1,2 +1,3 @@
 a
+b
 c
'
]);
