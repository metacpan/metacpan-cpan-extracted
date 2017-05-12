use strict;
use warnings FATAL => 'all';

use Test::More tests => 15;
use Data::Dumper;

BEGIN { use_ok('HTML::Tested', "HTV"); 
	use_ok('HTML::Tested::Test');
	use_ok('HTML::Tested::Value::DropDown');
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::DropDown", 'v');

package main;

my $object = T->new({ v => [
	[ 1, 'a', ],
	[ 2, 'b', ],
] });
is_deeply($object->v, [
	[ 1, 'a', ],
	[ 2, 'b', ],
]);

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<select id="v" name="v">
<option value="1">a</option>
<option value="2">b</option>
</select>
ENDS
is_deeply($object->v, [
	[ 1, 'a', ],
	[ 2, 'b', ],
]);

push @{ $object->v->[1] }, 1;
is_deeply($object->v, [
	[ 1, 'a', ],
	[ 2, 'b', 1, ],
]);
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<select id="v" name="v">
<option value="1">a</option>
<option value="2" selected="selected">b</option>
</select>
ENDS
is_deeply($object->v, [
	[ 1, 'a', ],
	[ 2, 'b', 1, ],
]);

$object->v->[1]->[1] = 'b<';
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<select id="v" name="v">
<option value="1">a</option>
<option value="2" selected="selected">b&lt;</option>
</select>
ENDS

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::DropDown", 'v', default_value => [
		[ "A", "One" ], [ "B", "Two" ] ]);

package main;

$object = T2->new;
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<select id="v" name="v">
<option value="A">One</option>
<option value="B">Two</option>
</select>
ENDS

$object->v('B');
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<select id="v" name="v">
<option value="A">One</option>
<option value="B" selected="selected">Two</option>
</select>
ENDS

$object->v(undef);
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<select id="v" name="v">
<option value="A">One</option>
<option value="B">Two</option>
</select>
ENDS

$object->ht_merge_params(v => 'B');
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<select id="v" name="v">
<option value="A">One</option>
<option value="B" selected="selected">Two</option>
</select>
ENDS

$object->v('B');
$object->ht_merge_params(v => 'A');
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<select id="v" name="v">
<option value="A" selected="selected">One</option>
<option value="B">Two</option>
</select>
ENDS


