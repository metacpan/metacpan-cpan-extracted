use strict;
use warnings FATAL => 'all';

use Test::More tests => 70;
use Data::Dumper;

BEGIN { use_ok('HTML::Tested::Seal');
	use_ok('HTML::Tested');
	use_ok('HTML::Tested::Test');
	use_ok('HTML::Tested::Test::Request');
	use_ok('HTML::Tested::Value::Hidden');
	use_ok('HTML::Tested::Value::Link');
	use_ok('HTML::Tested::List');
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::Value', 'v', is_sealed => 1);

package main;

my $s = HTML::Tested::Seal->instance('boo boo boo');
is_deeply(HTML::Tested::Seal->instance, $s);

my $v = $s->encrypt("hello");
isnt($v, "hello");
is($s->decrypt($v), "hello");
is($s->decrypt("dskdskd"), undef);
is(length($s->encrypt(1)), 16);

my $sec = HTML::Tested::Seal->instance->encrypt('secret');

is($s->encrypt("hello"), $v);
cmp_ok(length($v), '<=', length($s->encrypt("hello1")));

# And we confess
eval { $s->encrypt(undef); };
like($@, qr/$0/);

undef $HTML::Tested::Seal::_instance;
my $s2 = HTML::Tested::Seal->instance('boo boo boo');
isnt($s, $s2);
is($s2->decrypt($v), "hello");

my $v2 = $v;
my $res;
for my $i ('a' .. 'z', 0 .. 9) {
	substr($v2, -1) = $i;
	$res = $s->decrypt($v2);
	$res = undef if ($res && $res eq 'hello');
	last if $res;
}
is($res, undef);
is($s->decrypt($v), 'hello');
is(length($v), length($v2));

my $object = T->new({ v => 'hello' });
is($object->v, 'hello');

my $stash = {};
is($object->ht_get_widget_option("v", "is_sealed"), 1);
$object->ht_set_widget_option("v", "is_sealed", undef);

$object->ht_render($stash);
is_deeply($stash, { v => 'hello' }) or diag(Dumper($stash));

$stash = {};
$object->ht_set_widget_option("v", "is_sealed", 1);
$object->ht_add_widget('HTML::Tested::Value', 'b', is_sealed => 1);
$object->b($object->v);

$object->ht_render($stash);
ok(exists $stash->{v});
isnt($stash->{v}, 'hello');
is($s->decrypt($stash->{v}), 'hello');
is($stash->{v}, $stash->{b});

$res = T->ht_load_from_params(v => $stash->{v});
is($res->v, 'hello');

$res = T->ht_load_from_params(v => 'hello');
is($res->v, undef);

my $r = HTML::Tested::Test::Request->new;
$r->set_params({ HT_SEALED_v => 'hello', f => 'g' });
is($r->param('f'), 'g');
isnt($r->param('v'), 'hello');
isnt($r->param('v'), undef);
$res = T->ht_load_from_params(map { $_, $r->param($_) } $r->param);
is($res->v, 'hello');

$s = <<ENDS;
<html>
$stash->{v}
ENDS

# check_text first - uncovered bug in uninitialized $_seal_prefix
# becouse it is "my" the only way to check it is to fork.
is_deeply([ HTML::Tested::Test->check_text(ref($object), 
		$s, { HT_SEALED_v => 'hello' }) ], []);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => 'hello' }) ], []);

$object->v(undef);
$object->ht_render($stash);
ok(exists $stash->{v});
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { v => '' }) ]
	, [ 'HT_SEALED was not defined on v' ]);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => '' }) ], []);

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::Value::Hidden', 'v', is_sealed => 1);

package main;

$stash = {};
$object = T2->new({ v => 'hello' });
$object->ht_render($stash);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => 'hello' }) ], []);

# But we test it anyway... :)
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => 'hello1' }) ], [
'Mismatch at v: got "<input type="hidden" name="v" id="v" value="hello" />
", expected "<input type="hidden" name="v" id="v" value="hello1" />
"'
]);

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::Value::Hidden', 'h', is_sealed => 1);
__PACKAGE__->ht_add_widget('HTML::Tested::Value', 'v', is_sealed => 1);

package main;

$stash = {};
$object = T3->new({ h => 'bye', v => 'hello' });
$object->ht_render($stash);
$s = <<ENDS;
<html>
$stash->{h}
$stash->{v}
ENDS

is_deeply([ HTML::Tested::Test->check_text(ref($object), 
		$s, { HT_SEALED_v => 'hello', HT_SEALED_h => 'bye' }) ], []);

my @err = HTML::Tested::Test->check_text(ref($object), 
	$s, { HT_NO_HT_SEALED_v => 'hello', HT_SEALED_h => 'bye' });
is(@err, 1);
like($err[0], qr/Unexpectedly found "hello"/);

is_deeply([ HTML::Tested::Test->check_text(ref($object), 
	"sdfsfsdf", { HT_NO_HT_SEALED_v => 'hello' }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object), 
		$s, { HT_SEALED_v => 'hello', HT_SEALED_h => 'bye1' }) ], [
'Unable to find "<input type="hidden" name="h" id="h" value="bye1" />
" in "<html>
<input type="hidden" name="h" id="h" value="bye" />

hello
"'
]);

$r = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param(
		ref($object), $r, { HT_SEALED_v => 'V' });
is(HTML::Tested::Seal->instance->decrypt($r->param("v")), 'V');

package T4;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::Value::Link', 'v'
		, href_format => 'hello?id=%s&s=%s'
		, caption => "H", is_sealed => 1);
package main;

$object = T4->new({ v => [ 2, 'booo' ] });

$stash = {};
$object->ht_render($stash);
unlike($stash->{v}, qr/booo/) or diag(Dumper($stash));

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => [ 2, 'booo' ] }) ], []);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => [ 2, 'b1ooo' ] }) ], [
'Mismatch at v: got "<a id="v" href="hello?id=2&s=booo">H</a>
", expected "<a id="v" href="hello?id=2&s=b1ooo">H</a>
"'
]);

# The caption should not be encrypted.
$object->ht_set_widget_option('v', 'caption', undef);
$object->ht_find_widget('v')->options->{0} = { isnt_sealed => 1 };
$object->v([ 'moo', 'goo', 'boo' ]);
$stash = {};
$object->ht_render($stash);
unlike($stash->{v}, qr/goo/) or diag(Dumper($stash));
like($stash->{v}, qr/moo/) or diag(Dumper($stash));

# check_stash works on class level
T4->ht_set_widget_option('v', 'caption', undef);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => [ 'moo', 'goo', 'boo' ] }) ], []);

# Check that escaping is being done on sealed object:
# link caption should still be escaped
$object->v([ 'm&o', 'goo', 'boo' ]);
$stash = {};
$object->ht_render($stash);
unlike($stash->{v}, qr/boo/) or diag(Dumper($stash));
like($stash->{v}, qr/m&amp;o/) or diag(Dumper($stash));
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => [ 'm&o', 'goo', 'boo' ] }) ], []);

# check that escaping the parameters is not broken
$object->v([ 'm&o', 'go<', 'boo' ]);
$stash = {};
$object->ht_render($stash);
unlike($stash->{v}, qr/go/) or diag(Dumper($stash));

ok($stash->{v} =~ /id=(\w+)/);
$res = T->ht_load_from_params(v => $1);
is($res->v, 'go<');

my $sec2 = HTML::Tested::Seal->instance->encrypt('secret');
is($sec2, $sec);

undef $HTML::Tested::Seal::_instance;

HTML::Tested::Seal->instance('hrhr');
$object = T3->new({ h => 'bye', v => 'hello' });
is_deeply([ HTML::Tested::Test->check_text(ref($object), 
		$s, { HT_SEALED_v => 'hello', HT_SEALED_h => 'bye' }) ], [
'Unable to find "<input type="hidden" name="h" id="h" value="bye" />
" in "<html>
<input type="hidden" name="h" id="h" value="ENCRYPTED" />

ENCRYPTED
"',
'Unable to find "hello" in "<html>
<input type="hidden" name="h" id="h" value="ENCRYPTED" />

ENCRYPTED
"'
]);

package TU;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::Value', 'v');

package main;

$object = TU->new({ v => 'b' });
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => 'b' });
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_v => 'b' }) ], [ "v wasn't sealed b" ]);

package LN;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::Value', 'b' => is_sealed => 1);

package L;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget('HTML::Tested::List', l => 'TU');
__PACKAGE__->ht_add_widget('HTML::Tested::Value', 'v' => is_sealed => 1);

package main;

$object = L->new({ v => 1, l => [ LN->new({ b => 1 }) ] });
$object->ht_render($stash);
is($stash->{v}, $stash->{l}->[0]->{b});

$s2 = {};
$object->ht_render($s2);
is($s2->{v}, $stash->{v});
is($s2->{v}, $s2->{l}->[0]->{b});

$object->ht_render($s2);
is($s2->{v}, $s2->{l}->[0]->{b});

undef $HTML::Tested::Seal::_instance;
HTML::Tested::Seal->instance('boo boo boo');
is(HTML::Tested::Seal->instance->decrypt($sec2), 'secret');
is(HTML::Tested::Seal->instance->decrypt($sec), 'secret');

undef $HTML::Tested::Seal::_instance;
my $en1 = HTML::Tested::Seal->instance('boo')->encrypt('foo');

undef $HTML::Tested::Seal::_instance;
my $en2 = HTML::Tested::Seal->instance('boo')->encrypt('foo');
is($en1, $en2);

my @res;
for (1 .. 100) {
	undef $HTML::Tested::Seal::_instance;
	push @res, HTML::Tested::Seal->instance($_)->encrypt('foo');
}
is(@res, 100);
