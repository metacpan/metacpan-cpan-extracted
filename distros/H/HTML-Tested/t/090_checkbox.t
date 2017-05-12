use strict;
use warnings FATAL => 'all';

use Test::More tests => 17;
use Data::Dumper;
use HTML::Tested::Test;

BEGIN { use_ok('HTML::Tested', "HTV"); 
	use_ok('HTML::Tested::Value::CheckBox');
}

HTML::Tested::Seal->instance('boo boo boo');

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::CheckBox", 'v');

package main;

my $object = T->new({ v => [ 1 ] });
is_deeply($object->v, [ 1 ]);

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="checkbox" id="v" name="v" value="1" />
ENDS

push @{ $object->v }, 1;
is_deeply($object->v, [ 1, 1 ]);
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="checkbox" id="v" name="v" value="1" checked="1" />
ENDS

$object->v->[0] = "1\"f'";
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="checkbox" id="v" name="v" value="1&quot;f&#39;" checked="1" />
ENDS

$object->v->[0] = '1&';
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="checkbox" id="v" name="v" value="1&amp;" checked="1" />
ENDS

$object->v(1);
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="checkbox" id="v" name="v" value="1" checked="1" />
ENDS

$object->v(undef);
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="checkbox" id="v" name="v" value="1" />
ENDS

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::CheckBox", v => 0 => { is_sealed => 1 });

package main;

$object = T2->new({ v => [ 12 ] });
$stash = {};
$object->ht_render($stash);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ HT_SEALED_v => [ 12 ], }) ], [])
	or diag(Dumper($stash));

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::CheckBox", 'c1');
__PACKAGE__->ht_add_widget(::HTV."::CheckBox", 'c2', keep_undef => 1);
__PACKAGE__->ht_add_widget(::HTV."::CheckBox", 'c3');

package main;

$object = T3->ht_load_from_params;
is($object->c1, 0);
is($object->c2, undef);

$object->c3(1);

$stash = {};
$object->ht_render($stash);
is_deeply($stash, {
	c1 => '<input type="checkbox" id="c1" name="c1" value="1" />' . "\n"
	, c2 => '<input type="checkbox" id="c2" name="c2" value="1" />' . "\n"
	, c3 => '<input type="checkbox" id="c3" name="c3" value="1"'
		. ' checked="1" />' . "\n"
}) or diag(Dumper($stash));

$object->ht_merge_params(c1 => 1, c2 => 1, c3 => 1);
is($object->c1, 1);
is($object->c2, 1);
is($object->c3, 1);
