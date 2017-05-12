use strict;
use warnings FATAL => 'all';

use Test::More tests => 32;
use Data::Dumper;
use File::Temp qw(tempdir);
use File::Slurp;
use File::Spec;

BEGIN { use_ok('HTML::Tested', qw(HTV HT)); 
	use_ok(HT() . "::List");
	use_ok('HTML::Tested::Test::Request');
	use_ok('HTML::Tested::Test');
	use_ok('HTML::Tested::Value::Upload');
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Upload", 'v');

package main;

my $object = T->new;
is_deeply($object->v, undef);

my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="file" id="v" name="v" />
ENDS

my $td = tempdir(File::Spec->catdir(File::Spec->tmpdir, "plt_110_up_XXXXXX")
					, CLEANUP => 1);
write_file("$td/c.txt", "Hello\nworld\n");

my $req = HTML::Tested::Test::Request->new;
$req->add_upload(v => "$td/c.txt");
is(scalar($req->upload), 1);
is($req->upload(($req->upload)[0])->name, 'v');
is($req->upload(($req->upload)[0])->filename, "$td/c.txt");
is($req->upload(($req->upload)[0])->size, -s "$td/c.txt");
is(ref($req->upload(($req->upload)[0])->fh), 'GLOB');

my $res = T->ht_load_from_params(map { $_->name, $_ }
		map { $req->upload($_) } $req->upload);
is(ref($res->v), 'GLOB');
is(read_file($res->v), "Hello\nworld\n");

$req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param('T', $req, { v => "$td/c.txt" });
is_deeply([ $req->param ], []);
is(scalar($req->upload), 1);

my $u = $req->upload("v");
is($u->name, 'v');
is($u->filename, "$td/c.txt");
is(ref($u->fh), 'GLOB');

$req->add_upload(c => "$td/c.txt");
is($req->upload('c')->name, 'c');
is($req->upload('j'), undef);

package TC;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HT . "::List", l => 'T');

package main;
$object = TC->new({ l => [ map { T->new } (1 .. 2) ] });
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { l => [
	{ v => '<input type="file" id="l__1__v" name="l__1__v" />' . "\n" }
	, { v => '<input type="file" id="l__2__v" name="l__2__v" />' . "\n" }
] }) or diag(Dumper($stash));

T->ht_add_widget(::HTV, "b");

$req = HTML::Tested::Test::Request->new;
HTML::Tested::Test->convert_tree_to_param('TC', $req, { l => [
	{ b => 1 }, { v => "$td/c.txt" }, { b => 2, v => "$td/c.txt" } ] });
$object = TC->ht_load_from_params((map { $_->name, $_ }
		map { $req->upload($_) } $req->upload)
	, (map { $_, $req->param($_) } $req->param));
is($object->l->[0]->{b}, 1);
is(read_file($object->l->[1]->v), "Hello\nworld\n");
is(read_file($object->l->[2]->v), "Hello\nworld\n");
is($object->l->[2]->b, 2);

package T1;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Upload", 'v', object => 1);

package main;
$req = HTML::Tested::Test::Request->new;
$req->add_upload(v => "$td/c.txt");
$object = T1->ht_load_from_params(map { $_->name, $_ }
		map { $req->upload($_) } $req->upload);
isnt($object->v, undef);
is($object->v->filename, "$td/c.txt");
is($object->v->size, -s "$td/c.txt");
is($object->v->name, "v");
is(read_file($object->v->fh), "Hello\nworld\n");

# try to render it with v inside: no error should be produced
# useful for validation errors which reuse previous request
$stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => <<ENDS }) or diag(Dumper($stash));
<input type="file" id="v" name="v" />
ENDS

