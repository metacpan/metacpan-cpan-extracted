use strict;
use warnings FATAL => 'all';

use Test::More tests => 38;
use Data::Dumper;
use Carp;

BEGIN { use_ok('HTML::Tested', qw(HTV HT)); 
	use_ok('HTML::Tested::Value::Form');
	use_ok('HTML::Tested::Value::EditBox');
	use_ok('HTML::Tested::List');
	$SIG{__DIE__} = sub { confess(@_); };
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Form", 'v');

package main;

my $object = T->new;
is_deeply($object->v, undef);

$object->v('u');
my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<form id="v" name="v" method="post" action="u" enctype="multipart/form-data">
ENDS

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'a', default_value => 5);
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'b');
__PACKAGE__->ht_add_widget(::HTV."::Form", 'v', default_value => 'u');

package main;

$object = T2->new;
is_deeply($object->v, undef);
is_deeply($object->a, undef);
is_deeply($object->b, undef);

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS
<form id="v" name="v" method="post" action="u" enctype="multipart/form-data">
ENDS
	, a => <<ENDA
<input type="text" name="a" id="a" value="5" />
ENDA
	, b => <<ENDB
<input type="text" name="b" id="b" value="" />
ENDB
	 }) or diag(Dumper($stash));

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'b');
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'a', default_value => 5
		, constraints => [ [ regexp => '^\d+$' ] ]);
__PACKAGE__->ht_add_widget(::HTV."::Form", 'v', default_value => 'u');

package main;

$object = T3->new;
$object->a('ff');
is_deeply([ $object->ht_find_widget('a')->validate($object) ]
		, [ [ a => regexp => '^\d+$' ] ]);

$object->a(undef);
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<'ENDS'
<form id="v" name="v" method="post" action="u" enctype="multipart/form-data">
ENDS
	, a => <<ENDA
<input type="text" name="a" id="a" value="5" />
ENDA
	, b => <<ENDB
<input type="text" name="b" id="b" value="" />
ENDB
	 }) or diag(Dumper($stash));

package T4;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'a', default_value => 5
		, constraints => [ [ regexp => '^\d+$' ] ]);
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'b', constraints => [
		[ regexp => '^\d+$' ] ]);
__PACKAGE__->ht_add_widget(::HTV."::Form", 'v', default_value => 'u');

package main;

$object = T4->new;
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<'ENDS'
<form id="v" name="v" method="post" action="u" enctype="multipart/form-data">
ENDS
	, a => <<ENDA
<input type="text" name="a" id="a" value="5" />
ENDA
	, b => <<ENDB
<input type="text" name="b" id="b" value="" />
ENDB
	 }) or diag(Dumper($stash));

package T5;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::EditBox", $_) for qw(a b);
__PACKAGE__->ht_add_widget(::HTV."::Form", 'v', default_value => 'u');

package main;

$object = T5->new;
$stash = {};

is_deeply([ $object->ht_find_widget('a')->validate($object) ], []);
$object->ht_find_widget('a')->push_constraint([ regexp => '^\d+$' ]);
is_deeply([ $object->ht_find_widget('a')->validate($object) ]
		, [ [ 'a', regexp => '^\d+$' ] ]);
$object->a(5);
is_deeply([ $object->ht_find_widget('a')->validate($object) ], []);

$object->ht_find_widget('b')->push_constraint([ 'defined' => '' ]);
is_deeply([ $object->ht_find_widget('b')->validate($object) ]
		, [ [ b => 'defined' => '' ] ]);
$object->b('');
is_deeply([ $object->ht_find_widget('b')->validate($object) ], []);
$object->b(0);
is_deeply([ $object->ht_find_widget('b')->validate($object) ], []);

$object->b('');
$object->ht_render($stash);
is_deeply($stash, { v => <<'ENDS'
<form id="v" name="v" method="post" action="u" enctype="multipart/form-data">
ENDS
	, a => <<ENDA
<input type="text" name="a" id="a" value="5" />
ENDA
	, b => <<ENDB
<input type="text" name="b" id="b" value="" />
ENDB
	 }) or diag(Dumper($stash));

package T6;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::EditBox", 'a', constraints => [
	[ regexp => 'a' ], [ regexp => qr/b/ ]
]);

package main;

$object = T6->new;
$object->a('a');

is_deeply([ T6->ht_find_widget('a')->validate($object) ]
		, [ [ a => regexp => qr/b/ ] ]);
$object->a('b');
is_deeply([ T6->ht_find_widget('a')->validate($object) ]
		, [ [ a => regexp => 'a' ] ]);
$object->a('ba');
is_deeply([ T6->ht_find_widget('a')->validate($object) ], []);

$object = T6->new;
my @val = $object->ht_validate;
is_deeply([ @val ], [ [ a => regexp => 'a' ], [ a => regexp => qr/b/ ] ]);
my $err = T6->ht_encode_errors(@val);
is($err, 'a:regexp,a:regexp');

$stash = {};
$object->a('bbb');
$object->ht_render($stash);
is_deeply($stash, { a => '<input type="text" name="a" id="a" value="bbb" />'
	. "\n" }) or diag(Dumper($stash));

T6->ht_error_render($stash, 'foo_e', $err);
is_deeply($stash, { a => '<input type="text" name="a" id="a" value="bbb" />'
	. "\n", foo_e => { a => 'regexp' } }) or diag(Dumper($stash));

package T7;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", l1 => 'T6');

package main;
$object = T7->new;
is_deeply([ $object->ht_validate ], []);

$object = T7->new({ l1 => [ T6->new({ a => 'bbb' }) ] });
my $res = [ $object->ht_validate ];
is_deeply($res, [ [ l1__1__a => regexp => 'a' ] ]) or diag(Dumper($res));

$object->l1->[0]->a("bab");
is_deeply([ $object->ht_validate ], []);

push @{ $object->l1 }, T6->new({ a => 'aaa' });
$res = [ $object->ht_validate ];
is_deeply($res, [ [ l1__2__a => regexp => qr/b/ ] ]) or diag(Dumper($res));

$stash = {};
$object->ht_render($stash);
is_deeply($stash, { l1 => [ {
	a => '<input type="text" name="l1__1__a" id="l1__1__a" value="bab" />'
		. "\n"
}, {
	a => '<input type="text" name="l1__2__a" id="l1__2__a" value="aaa" />'
		. "\n"
} ] }) or diag(Dumper($stash));

$object->ht_error_render($stash, 'bar_e', T6->ht_encode_errors(@$res));
is_deeply($stash, { l1 => [ {
	a => '<input type="text" name="l1__1__a" id="l1__1__a" value="bab" />'
		. "\n"
}, {
	a => '<input type="text" name="l1__2__a" id="l1__2__a" value="aaa" />'
		. "\n"
	, bar_e => { a => 'regexp' }
} ] }) or diag(Dumper($stash));

T6->ht_set_widget_option("a", "no_validate", 1);
$object->l1->[0]->a("bb");
is_deeply([ $object->ht_validate ], []);

package T8;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, v => is_integer => 1);

package main;
$object = T8->new({ v => 'a' });
is_deeply([ $object->ht_validate ], [ [ v => 'integer' ] ]);

$object->v(12);
is_deeply([ $object->ht_validate ], []);

$object->v(undef);
is_deeply([ $object->ht_validate ], []);

$object->v('');
is_deeply([ $object->ht_validate ], [ [ v => 'integer' ] ]);
