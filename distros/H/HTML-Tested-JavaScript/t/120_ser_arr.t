use strict;
use warnings FATAL => 'all';

use Test::More tests => 16;
use HTML::Tested::Seal;
use Text::Diff;
use HTML::Tested::Test::Request;

BEGIN { use_ok('HTML::Tested::JavaScript::Serializer::Array');
	use_ok('HTML::Tested::JavaScript::Serializer');
	use_ok('HTML::Tested::JavaScript::Test');
	use_ok('HTML::Tested::JavaScript::Serializer::List');
}

my $seal = HTML::Tested::Seal->instance('boo');

package MA;
use base "HTML::Tested::JavaScript::Serializer::Array";
sub unseal_value {
	my ($self, $val, $caller) = @_;
	return "ma";
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Array", "sv");
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Array", "as"
		, is_sealed => 1);
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer", "ser", "sv");

package main;
my $obj = T->new({ sv => [ "aa", "bb" ], as => [] });
my $stash = {};
$obj->ht_render($stash);
is($stash->{ser} . "\n", <<'ENDS');
<script src="/html-tested-javascript/serializer.js"></script>
<script>//<![CDATA[
var ser = {
	"sv": [ "aa", "bb" ]
};//]]>
</script>
ENDS

is_deeply([ HTML::Tested::Test->check_stash(ref($obj), $stash, { ser => ''
	, HT_SEALED_as => [], sv => [ "aa", "bb" ] }) ], []) or exit 1;

$obj->as([ 1, 2 ]);
$stash = {};
$obj->ht_render($stash);
my $re = $seal->encrypt(1) . ".*" . $seal->encrypt(2);
like($stash->{as}, qr/$re/);

package T1;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::Array", "ar");

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer::List"
					, "l", 'T1');
__PACKAGE__->ht_add_widget("HTML::Tested::JavaScript::Serializer", "ser", "l");

package main;
$obj = T2->new({ l => [ map { T1->new({ ar => [ "a", "b" ] }) } (1 .. 2) ] });
$stash = {};
$obj->ht_render($stash);

my $ser_exp = <<'ENDS';
<script src="/html-tested-javascript/serializer.js"></script>
<script>//<![CDATA[
var ser = {
	"l": [ {
	"ar": [ "a", "b" ]
}, {
	"ar": [ "a", "b" ]
} ]
};//]]>
</script>
ENDS

my $ser_res = $stash->{ser} . "\n";
is(diff(\$ser_res, \$ser_exp), '');

T->ht_add_widget("MA", "us" , is_sealed => 1);
$obj = T->ht_load_from_params(sv => "a,b", as => $seal->encrypt("f")
		, us => "kk");
is_deeply($obj->sv, [ "a", "b" ]);
is_deeply($obj->as, [ "f" ]);
is_deeply($obj->us, [ "ma" ]);

$obj = T->ht_load_from_params(sv => "0");
is_deeply($obj->sv, [ "0" ]);

my $req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param('T', $req, {
	HT_SEALED_as => [ 'a', 'b' ], sv => [] });
is($req->param('as'), $seal->encrypt('a') . "," . $seal->encrypt('b'));
is($req->param('sv'), '');

$obj = T->ht_load_from_params(as => $req->param('as'));
is_deeply($obj->as, [ "a", "b" ]);

$req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param('T', $req, { HT_SEALED_as => [] });
is($req->param('as'), '');
