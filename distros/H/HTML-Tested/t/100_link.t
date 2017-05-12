use strict;
use warnings FATAL => 'all';

use Test::More tests => 17;
use Data::Dumper;
use HTML::Tested::Test;

BEGIN { use_ok('HTML::Tested', qw(HTV));
	use_ok('HTML::Tested::Value::Link');
	use_ok('HTML::Tested::Value::Marked');
}

HTML::Tested::Seal->instance('boo boo boo');

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Link", 'v');

package main;

my $object = T->new({ v => [ 'H', 2 ] });
is_deeply($object->v, [ 'H', 2 ]);

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<a id="v" href="2">H</a>
ENDS

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Link", 'v'
		, href_format => 'hello?id=%d&s=%s');

package main;

$object = T2->new({ v => [ 'H', 2, 'b&' ] });

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<a id="v" href="hello?id=2&s=b&amp;">H</a>
ENDS

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Link", 'v'
		, href_format => 'hello?id=%d&s=%s', caption => "H");

package main;

$object = T3->new({ v => [ 2, 'b&' ] });

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<a id="v" href="hello?id=2&s=b&amp;">H</a>
ENDS

package T4;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Link", 'v'
		, href_format => 'hello?s=%s&id=%s'
		, caption => "H", 1 => { is_sealed => 1 });
__PACKAGE__->ht_add_widget(::HTV, s => is_sealed => 1);

package main;
$object = T4->new({ v => [ 'b', 12 ], s => 12 });

$stash = {};
$object->ht_render($stash);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ HT_SEALED_v => [ b => 12 ], HT_SEALED_s => 12 }) ], [])
	or diag(Dumper($stash));
my $s = $stash->{s};
like($stash->{v}, qr/$s/);

package H1;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Marked", "a");

package H2;
use base 'H1';
__PACKAGE__->ht_add_widget(::HTV."::Marked", "b");

package main;
my $h2 = H2->new({ a => 'A', b => 'B' });
is($h2->a, 'A');
is($h2->b, 'B');

$stash = {};
$h2->ht_render($stash, "some_app_dependent_important_parameter");
is_deeply($stash, { a => '<!-- a --> A', b => '<!-- b --> B' })
	or diag(Dumper($stash));

package H3;
use base 'H2';
__PACKAGE__->ht_add_widget(::HTV."::Marked", "c", skip_undef => 1);

sub ht_render {
	my ($self, $stash, $p1, $p2) = @_;
	$self->c($p2);
	shift()->SUPER::ht_render(@_);
}

package main;
my $h3 = H3->new({ a => 'A', b => 'B' });
$stash = {};
$h3->ht_render($stash, "p1", "p2");
is_deeply($stash, { a => '<!-- a --> A', b => '<!-- b --> B'
	, c => '<!-- c --> p2' }) or diag(Dumper($stash));

is_deeply([ HTML::Tested::Test->check_stash(ref($h3), 
		$stash, { c => 'p2' }) ], []);

is_deeply([ HTML::Tested::Test->check_stash(ref($h3), 
		$stash, { c => 'p4' }) ], [
	'Mismatch at c: got "<!-- c --> p2", expected "<!-- c --> p4"'
]);

is_deeply([ HTML::Tested::Test->check_text(ref($h3), 
		"foo <!-- c --> p2 foo", { c => 'p5' }) ], [
	'Unable to find "<!-- c --> p5" in "foo <!-- c --> p2 foo"'
]);

is_deeply([ HTML::Tested::Test->check_text(ref($h3), 
		"foo <!-- c --> p2 foo", { c => 'p2' }) ], []);
