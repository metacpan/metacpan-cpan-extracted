use strict;
use warnings FATAL => 'all';

use Test::More tests => 26;
use HTML::Tested::Test;

BEGIN { use_ok('HTML::Tested::Value::Snippet');
	use_ok('HTML::Tested', 'HTV');
	use_ok('HTML::Tested::Value::EditBox');
	use_ok('HTML::Tested::Value::DropDown');
	use_ok('HTML::Tested::Value::CheckBox');
	use_ok('HTML::Tested::List');
	use_ok('HTML::Tested::Test::Request');
}

package T;
use base 'HTML::Tested';

__PACKAGE__->ht_add_widget(::HTV, "v");
__PACKAGE__->ht_add_widget(::HTV . "::Snippet", sni => is_trusted => 1);

package main;

my $obj = T->new({ v => "&hi", sni => "<b>[% v %]</b>" });
my $stash = {};
$obj->ht_render($stash);
is_deeply($stash, { v => '&amp;hi', sni => "<b>&amp;hi</b>" });

# two styles of tests are possible: direct comparison and through render
is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash, {
			sni => "<b>&amp;hi</b>" }) ], []);
is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash, {
			v => "&hi", sni => "<b>[% v %]</b>" }) ], []);

# check that trusted doesn't load from param
T->ht_set_widget_option(sni => default_value => '[% foo');
$obj = T->ht_load_from_params(v => 'f', sni => 'k');
is($obj->v, 'f');
is($obj->sni, undef);
$obj->ht_render($stash);
is_deeply($stash, { v => 'f', sni => "[% foo" });

my $req = HTML::Tested::Test::Request->new({ uri => 'g' });
is($req->uri, 'g');
is($req->hostname, "some.host");
is($req->server, $req);
is($req->port, 80);

# check that set_params clears old ones
$req->set_params({ foo => 'boo' });
$req->set_params({ goo => 'woo' });
is($req->param('foo'), undef);
is_deeply(\%{ $req->param }, { goo => 'woo' });

$req->param('a', undef);
is_deeply(\%{ $req->param }, { goo => 'woo', a => undef });

# todo: default_value, check, uncheck

package T1;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV . "::EditBox", "eb");
__PACKAGE__->ht_add_widget(::HTV . "::DropDown", "dd");

package main;
my $c = T1->ht_add_widget("HTML::Tested::List", "l")->containee;
$c->ht_add_widget(::HTV . "::CheckBox", "ch1");

$obj = T1->new({ eb => 'foo', l => [ $c->new({ ch1 => [ 284 ] }) ] });

$obj->ht_merge_params(eb => 'goo', l__1__ch1 => 1);
is($obj->eb, 'goo');
is_deeply($obj->l->[0]->ch1, [ 284, 1 ]);

$obj = T1->new({ dd => [ [ 1, 'A', 1 ], [ 2, 'B' ] ] });
$obj->ht_merge_params(dd => 2);
is_deeply($obj->dd, [ [ 1, 'A', "" ], [ 2, 'B', 1 ] ]);

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV . "::EditBox", "eb1");
__PACKAGE__->ht_add_widget(::HTV . "::EditBox", "eb2", keep_empty_string => 1);

package main;

$obj = T2->ht_load_from_params(eb1 => "", eb2 => "");
is($obj->eb1, undef);
is($obj->eb2, "");
ok(exists $obj->{eb1});

