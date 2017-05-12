use strict;
use warnings FATAL => 'all';

use Test::More tests => 8;
use HTML::Tested::Test;
use HTML::Tested::Seal;

BEGIN { use_ok('HTML::Tested::JavaScript', qw(HTJ));
	use_ok('HTML::Tested::JavaScript::Serializer');
	use_ok('HTML::Tested::JavaScript::Test');
	use_ok('HTML::Tested::JavaScript::Serializer::Value');
	use_ok('HTML::Tested::JavaScript::Serializer::List');
}

HTML::Tested::Seal->instance("ggg");

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTJ . "::Serializer::Value", "sv", is_sealed => 1);
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer", "ser", "sv");

package main;

my $obj = T->new({ sv => 'a' });
my $stash = {};
is_deeply([ $obj->ht_validate ], []);
$obj->ht_render($stash);

is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash,
		{ ser => '', HT_SEALED_sv => 'a' }) ], []);

package T1;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Value", "sv", is_sealed => 1);

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::List", "l", 'T1');
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer", "ser", "l");

package main;

$obj = T2->new({ l => [ T1->new({ sv => 'a' }) ] });
$stash = {};
$obj->ht_render($stash);

is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash,
		{ ser => '', l => [ { HT_SEALED_sv => 'a' } ] }) ], []);

