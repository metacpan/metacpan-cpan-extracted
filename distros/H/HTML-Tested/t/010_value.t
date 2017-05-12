use strict;
use warnings FATAL => 'all';

use Test::More tests => 47;
use Data::Dumper;
use HTML::Tested::Test::Request;

BEGIN { use_ok('HTML::Tested', 'HT', 'HTV'); 
	use_ok('HTML::Tested::Test', 'Register_Widget_Tester'); 
	use_ok('HTML::Tested::Value'); 
	use_ok('HTML::Tested::Value::Marked'); 
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::Value", 'v', default_value => 'xxx');

package main;

my $object = T->new({ v => 'b' });
is($object->v, 'b');

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => 'b' }) or diag(Dumper($stash));

T->ht_add_widget(::HT."::Value::Marked", 'mv');
$object->mv('c');
$object->ht_render($stash);
is_deeply($stash, { v => 'b', mv => '<!-- mv --> c' })
	or diag(Dumper($stash));

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { v => 'b', mv => 'c' }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object), 
	'This b is ok <!-- mv --> c', { v => 'b', mv => 'c' }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object), 
		'This is not ok c', { mv => 'c' }) ], [
	'Unable to find "<!-- mv --> c" in "This is not ok c"' ]);

my $req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param('T', $req
		, { v => 'b', mv => 'c' });
is_deeply($req->_param, { v => 'b', mv => 'c' });

$object->mv(undef);
$object->ht_render($stash);
is_deeply($stash, { v => 'b', mv => '<!-- mv --> ' })
	or diag(Dumper($stash));
is($req->body_status, 'Success');

$object->v(undef);
$object->ht_render($stash);
is_deeply($stash, { v => 'xxx', mv => '<!-- mv --> ' })
	or diag(Dumper($stash));

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::Value", 'ht_id');

package main;

$req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param('T2', $req, { ht_id => 5 });
is_deeply($req->_param, { ht_id => 5});

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::Value", 'v', is_disabled => 1);

package main;

$object = T3->new({ v => 'b' });
is($object->v, 'b');

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => '' }) or diag(Dumper($stash));

is($object->ht_get_widget_option("v", "is_disabled"), 1);
$object->ht_set_widget_option("v", "is_disabled", undef);
is($object->ht_get_widget_option("v", "is_disabled"), undef);

eval { $object->ht_get_widget_option("fff", "is_disabled"); };
like($@, qr/Unknown widget fff/);

eval { $object->ht_set_widget_option("fff", "is_disabled", 1); };
like($@, qr/Unknown widget fff/);

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => 'b' }) or diag(Dumper($stash));

$object = T3->new({ v => 'b' });
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => '' }) or diag(Dumper($stash));

is(T3->ht_get_widget_option("v", "is_disabled"), 1);
T3->ht_set_widget_option("v", "is_disabled", undef);
$object = T3->new({ v => 'b' });
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => 'b' }) or diag(Dumper($stash));
is($object->ht_get_widget_option("v", "is_disabled"), undef);

package T4;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::Value", 'v', is_trusted => 1
		, default_value => sub {
	my ($self, $id, $caller) = @_;
	return $self->name . ", $id, " . ref($caller);
});

package main;

$object = T4->new({ v => '&a' });
is($object->v, '&a');

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => '&a' }) or diag(Dumper($stash));

$object->v(undef);
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => 'v, v, T4' }) or diag(Dumper($stash));

my (@_uv, @_sv);

package TV;
use base 'HTML::Tested::Value';

sub seal_value {
	my ($self, $val, $caller) = @_;
	@_sv = ($val, $caller);
	return $val;
}

sub unseal_value {
	my ($self, $val, $caller) = @_;
	@_uv = ($val, $caller);
	return $val;
}

package T5;
use base 'HTML::Tested';

__PACKAGE__->ht_add_widget("TV", tv => is_sealed => 1);

package main;

my $t5 = T5->ht_load_from_params(tv => 'a');
is($t5->tv, 'a');
is($_uv[0], 'a');
is($_uv[1], $t5);

$stash = {};
$t5->ht_render($stash);
is_deeply($stash, { tv => 'a' });
is_deeply(\@_uv, \@_sv);

my @_e;
my $_ms = 1;

my $seal = HTML::Tested::Seal->instance('aaa');

package TVT;
use base 'HTML::Tested::Test::Value';

sub is_marked_as_sealed {
	my ($class, $e_root, $name) = @_;
	return $_ms ? $class->SUPER::is_marked_as_sealed($e_root, $name) : 0;
}

sub handle_sealed {
	my ($class, $e_root, $name, $e_val, $r_val, $err) = @_;
	$class->SUPER::handle_sealed($e_root, $name, $e_val, $r_val, \@_e);
}

sub convert_to_sealed {
	my ($self, $val) = @_;
	return [ map { $seal->encrypt($_) } @$val ];
}

sub convert_to_param {
	my ($class, $obj_class, $r, $name, $val) = @_;
	return $class->SUPER::convert_to_param($obj_class, $r, $name
			, join("|", @$val));
}

package main;
Register_Widget_Tester('TV', 'TVT');

is_deeply([ HTML::Tested::Test->check_stash('T5', $stash, {
		HT_SEALED_tv => 'a' }) ], []);
is_deeply(\@_e, [ "tv wasn't sealed a" ]);

$_ms = undef;
@_e = ();
is_deeply([ HTML::Tested::Test->check_stash('T5', $stash, {
		HT_SEALED_tv => 'a' }) ], []);
is_deeply(\@_e, [ 'HT_SEALED was not defined on tv' ]);

package T6;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, uv => skip_undef => 1);

package main;

$object = T6->new;
$stash = {};
$object->ht_render($stash);
is_deeply($stash, {}) or diag(Dumper($stash));
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
	$stash, { uv => '' }) ], [ 'Mismatch at uv: got undef, expected ""' ]);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
	$stash, { uv => undef }) ], []);

$object->uv(1);
$object->ht_render($stash);
is_deeply($stash, { uv => 1 }) or diag(Dumper($stash));
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
	$stash, { uv => undef }) ], []);
is_deeply([ HTML::Tested::Test->check_text(ref($object), 
	"mooo", { uv => undef }) ], []);

$object->ht_set_widget_option("uv", "is_sealed", 1);
$object->uv(undef);
$stash = {};
$object->ht_render($stash);
is_deeply($stash, {}) or diag(Dumper($stash));
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
	$stash, { HT_SEALED_uv => '' }) ]
		, [ 'Mismatch at uv: got undef, expected ""' ]);

$req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param('T5', $req
		, { HT_SEALED_tv => [ "a", "b" ] });
is($req->param("tv"), $seal->encrypt("a") . "|" . $seal->encrypt("b"));
