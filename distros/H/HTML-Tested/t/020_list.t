use strict;
use warnings FATAL => 'all';

use Test::More tests => 40;
use Data::Dumper;
use Carp;
use HTML::Tested::Test::Request;

BEGIN { $SIG{__DIE__} = sub { confess("# " . $_[0]); }; };

BEGIN { use_ok('HTML::Tested::List'); 
	use_ok('HTML::Tested', "HTV", "HT"); 
	use_ok('HTML::Tested::Test'); 
	use_ok('HTML::Tested::Value::Marked'); 
	use_ok('HTML::Tested::List'); 
}

package L;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", 'l1', 'LR');

package LR;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Marked", 'v1');

sub make_test_array {
	my $class = shift;
	return [ map { LR->new({ v1 => $_ }) } @_ ];
}

package main;

my $object = L->new({ l1 => [] });
is_deeply($object->l1, []);

$object->l1([ map { LR->new({ v1 => $_ }) } qw(a b) ]);
my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { l1 => [ { v1 => '<!-- l1__1__v1 --> a' }, 
				{ v1 => '<!-- l1__2__v1 --> b' } ] }) 
	or diag(Dumper($stash));
is($object->l1_containee, 'LR');

$object->l1(undef);
my $exp = [ map { LR->new({ v1 => $_ }) } qw(a b) ];
is_deeply($object->l1_containee_do(qw(make_test_array a b)), $exp);
is_deeply($object->l1, $exp);

my $tree ={ l1 => [ { v1 => 'a' }, { v1 => 'b' }, ] };
my $res = L->ht_load_from_params(l1__2__v1 => 'b', l1__1__v1 => 'a');
isa_ok($res, 'L');
is_deeply($res, $tree) or diag(Dumper($res));
is($res->l1->[1]->v1, 'b');

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ l1 => [ { v1 => 'a' }, 
				{ v1 => 'b' } ] }) ], []);

eval { HTML::Tested::Test->check_stash(ref($object), $stash, { l1 => "" }) };
like($@, qr/l1 should be ARRAY reference/);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
			{ l1 => [ { }, { } ] }) ], []);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
			{ l1 => [ { xxxx => 'ddd' }, 
					{ } ] }) ], [
		'Unknown widget xxxx found in expected!' ]);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
			{ l1 => [ { }, ] }) ], [
q#Stash $VAR1 = {
          'v1' => '<!-- l1__2__v1 --> b'
        };
differ from expected $VAR1 = undef;
# ]);

is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
			{ l1 => [ { v1 => 'c' }, 
					{ } ] }) ], [ 
'Mismatch at v1: got "<!-- l1__1__v1 --> a", expected "<!-- l1__1__v1 --> c"'
]);

is_deeply([ HTML::Tested::Test->check_text(ref($object),
			'<!-- l1__1__v1 --> a <!-- l1__2__v1 --> b',
			{ l1 => [ { v1 => 'a' }, 
					{ v1 => 'b' } ] }) ], []);

is_deeply([ HTML::Tested::Test->check_text(ref($object),
			'<!-- l1__1__v1 --> a b',
			{ l1 => [ { v1 => 'a' }, 
					{ v1 => 'b' } ] }) ], [
	'Unable to find "<!-- l1__2__v1 --> b" in "<!-- l1__1__v1 --> a b"' ]);

my $req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param(ref($object), $req, 
		{ l1 => [ { v1 => 'a' }, { v1 => 'b' } ] });
is_deeply($req->_param, { l1__1__v1 => 'a', l1__2__v1 => 'b' })
	or diag(Dumper($req));

package NL;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", 'l1', 'NLR');

package NLR;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", 'l2', 'LR');

package main;

my $nested = NL->new({ l1 => [ map { NLR->new({ l2 => [ 
				map  { LR->new({ v1 => $_ }) } qw(a b) ] }) } 
		(1 .. 2) ]});
$stash = {};
$nested->ht_render($stash);
is_deeply($stash, { l1 => [ { 
	l2 => [ { v1 => '<!-- l1__1__l2__1__v1 --> a' }, 
				{ v1 => '<!-- l1__1__l2__2__v1 --> b' } ],
}, {
	l2 => [ { v1 => '<!-- l1__2__l2__1__v1 --> a' }, 
				{ v1 => '<!-- l1__2__l2__2__v1 --> b' } ],
} ] }) 
	or diag(Dumper($stash));
my $blessed = NL->ht_bless_from_tree({
	l1 => [ { l2 => [ { v1 => 'a' }, 
					{ v1 => 'a' } ] },
		{ l2 => [ { v1 => 'b' }, 
					{ v1 => 'b' } ] }
	] });
is(@{ $blessed->l1 }, 2);
is(@{ $blessed->l1->[1]->l2 }, 2);

package L2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", 'l1', 'LR2');

package LR2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Marked", 'v1');
__PACKAGE__->ht_add_widget(::HTV, 'ht_id');

package main;

$req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param('L2', $req, 
		{ l1 => [ { ht_id => 1, v1 => 'a' }, 
				{ ht_id => 2, v1 => 'b' } ] });
is_deeply($req->_param, { l1__1__v1 => 'a', l1__2__v1 => 'b'
		, l1__2__ht_id => 2, l1__1__ht_id => 1 })
	or diag(Dumper($req));

$res = L2->ht_load_from_params(map { $_, $req->param($_) } $req->param);
$tree ={ l1 => [ { v1 => 'a', ht_id => 1 }, { ht_id => 2, v1 => 'b' }, ] };
is_deeply($res, $tree) or diag(Dumper($res));

package X;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", 'department_list', 'X2');

package X2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, $_) for qw(building_dropdown office_edit);

package main;

$req = HTML::Tested::Test::Request->new({ _param => {
	'department_list__2__building_dropdown' => '1',
	'department_list__2__office_edit' => '2',
} });

$tree = X->ht_load_from_params(map { $_, $req->param($_) } $req->param);
is_deeply($tree->department_list, [ {
	office_edit => 2, building_dropdown => 1
} ]) or diag(Dumper($tree));

package X2I;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, a => is_sealed => 1);
__PACKAGE__->ht_add_widget(::HTV, 'b');

package X2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", l => 'X2I');

package main;
HTML::Tested::Seal->instance('hrhr');
$object = X2->new({ l => [ map { X2I->new({ a => $_, b => ($_ + 1) }) }
					(1 .. 2) ] });
$stash = {};
$object->ht_render($stash);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ l => [ { b => 2 }, { HT_SEALED_a => 2 } ] }) ], []);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ l => [ { HT_SEALED_a => 1 }, { b => 3 } ] }) ], []);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ l => [ { HT_SEALED_a => 1 }, { b => 4 } ] }) ], [
			'Mismatch at b: got "3", expected "4"' ]);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ HT_UNSORTED_l => [ { HT_SEALED_a => 1 }, { b => 3 } ] }) ]
			, []);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ HT_UNSORTED_l => [ { b => 3 }, { HT_SEALED_a => 1 } ] }) ]
			, []);
is_deeply([ HTML::Tested::Test->check_stash(ref($object), $stash,
		{ HT_UNSORTED_l => [ { b => 4 }, { HT_SEALED_a => 1 } ] }) ]
			, [ 'Mismatch at b: got "3", expected "4"' ]);

package H100I;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV, "a");

package HT100;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", l => 'H100I');

package main;

my $obj = HT100->ht_load_from_params(map { ("l__$_\__a" => $_) } (1 .. 100));
is_deeply([ map { $_->a } @{ $obj->l } ], [ (1 .. 100) ]);
$obj = HT100->ht_load_from_params;
is_deeply($obj->l, []);

my ($ic1, $ic2);
package HT101;
use base 'HTML::Tested';
$ic1 = __PACKAGE__->ht_add_widget(::HT."::List", 'l1')->containee;
$ic2 = __PACKAGE__->ht_add_widget(::HT."::List", 'l2')->containee;

package main;

isnt($ic1, $ic2);
$ic1->ht_add_widget(::HTV, "v1");
$ic2->ht_add_widget(::HTV, "v2");

$obj = HT101->ht_load_from_params(l1__1__v1 => "a", l2__1__v2 => "b");
$stash = {};
$obj->ht_render($stash);
is_deeply($stash, { l1 => [ { v1 => 'a' } ], l2 => [ { v2 => 'b' } ] });

package HT102;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT."::List", 'l1', undef, cbase => 'H100I');

package main;
$obj = HT102->ht_load_from_params(l1__1__a => "a");
$stash = {};
$obj->ht_render($stash);
is_deeply($stash, { l1 => [ { a => 'a' } ] }) or diag(Dumper($stash));

my @_fvs;

package FV;
use base 'HTML::Tested::Value';

sub finish_load {
	my ($self, $root) = @_;
	push @_fvs, $self->name, $root->{ $self->name };
}

package HT103;
use base 'HTML::Tested';
my $lic = __PACKAGE__->ht_add_widget(::HT."::List", 'l1')->containee;
__PACKAGE__->ht_add_widget('FV', 'fv103');
$lic->ht_add_widget('FV', 'lic50');

package main;
$obj = HT103->ht_load_from_params(l1__1__lic50 => "a", l1__2__lic50 => "b"
		, fv103 => 'c');
is_deeply(\@_fvs, [ qw(lic50 a lic50 b fv103 c) ]);
