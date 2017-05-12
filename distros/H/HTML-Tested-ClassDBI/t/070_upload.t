use strict;
use warnings FATAL => 'all';

use Test::More tests => 45;
use File::Temp qw(tempdir);
use File::Slurp;
use File::Spec;
use Test::TempDatabase;
use HTML::Tested::Value::Link;
use HTML::Tested::Test;

BEGIN { use_ok('HTML::Tested', qw(HTV)); 
	use_ok('HTML::Tested::Test::Request');
	use_ok('HTML::Tested::Value::Upload');
}

HTML::Tested::Seal->instance('boo boo boo');

my $tdb = Test::TempDatabase->create(dbname => 'ht_class_dbi_test',
		dbi_args => { RootClass => 'DBIx::ContextualFetch'
			, RaiseError => 1, PrintError => undef });
my $dbh = $tdb->handle;
$dbh->do('SET client_min_messages TO error');
$dbh->do("CREATE TABLE table1 (id serial primary key, v oid not null)");

package CDBI_Base;
use base 'Class::DBI::Pg::More';

sub db_Main { return $dbh; }

package CDBI;
use base 'CDBI_Base';

__PACKAGE__->set_up_table('table1', { ColumnGroup => 'Essential' });

package T;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV."::Upload", v => cdbi_upload => "");
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;

my $td = tempdir(File::Spec->catdir(File::Spec->tmpdir, "plt_110_up_XXXXXX")
					, CLEANUP => 1);
write_file("$td/c.txt", "Hello\nworld\n");

my $req = HTML::Tested::Test::Request->new;
$req->add_upload(v => "$td/c.txt");

my $obj = T->ht_load_from_params(map { ($_, $req->upload($_)) } $req->upload);
is(ref($obj->v), 'GLOB');
T->CDBI_Class->db_Main->begin_work;
$obj->cdbi_create_or_update;
T->CDBI_Class->db_Main->commit;
isnt($obj->class_dbi_object->v, undef);

T->CDBI_Class->db_Main->begin_work;
my $res = $dbh->func($obj->class_dbi_object->v, "$td/a", 'lo_export');
T->CDBI_Class->db_Main->commit;
ok($res);
is(read_file("$td/a"), read_file("$td/c.txt"));

package T2;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV."::Link", 'elink'
		, cdbi_bind => [ v => 'Primary' ]);
__PACKAGE__->ht_add_widget(::HTV."::Upload", upo => cdbi_upload => "v");
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;
my $t2 = T2->new({ id => $obj->id });
isnt($t2->cdbi_load, undef);
is($t2->class_dbi_object->v, $obj->class_dbi_object->v);

my $stash = {};
$t2->ht_render($stash);
is_deeply([ HTML::Tested::Test->check_stash(ref($t2), 
		$stash, { HT_SEALED_id => 1, HT_SEALED_elink => [
				$obj->class_dbi_object->v, 1 ] }) ], []);

$req = HTML::Tested::Test::Request->new;
$req->add_upload(upo => "$td/c.txt");

$obj = T2->ht_load_from_params(map { ($_, $req->upload($_)) } $req->upload);
is(ref($obj->upo), 'GLOB');
T->CDBI_Class->db_Main->begin_work;
$obj->cdbi_create_or_update;
T->CDBI_Class->db_Main->commit;
isnt($obj->class_dbi_object->v, undef);

package T3;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV."::Upload", v => cdbi_upload_with_mime => "");
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;

$req = HTML::Tested::Test::Request->new;
$req->add_upload(v => "$td/c.txt");

$obj = T3->ht_load_from_params(map { ($_, $req->upload($_)) } $req->upload);
is(ref($obj->v), 'GLOB');
T->CDBI_Class->db_Main->begin_work;
$obj->cdbi_create_or_update;
T->CDBI_Class->db_Main->commit;
isnt($obj->class_dbi_object->v, undef);

# without that it won't work in Apache. See Apache::SWIT t/080_upload.t
is(ref($obj->v), 'FileHandle');

T->CDBI_Class->db_Main->begin_work;
$res = $dbh->func($obj->class_dbi_object->v, "$td/a", 'lo_export');
T->CDBI_Class->db_Main->commit;
ok($res);

$res = read_file("$td/a");
like($res, qr#text/plain#);
my @sres = HTML::Tested::ClassDBI::Upload->strip_mime_header($res);
is($sres[1], read_file("$td/c.txt"));
is($sres[0], "text/plain");

package T4;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV."::Upload", upo => cdbi_upload_with_mime =>
				"v");
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;

$req = HTML::Tested::Test::Request->new;
my $tp = `which true`;
chomp($tp);
$req->add_upload(upo => $tp);

$obj = T4->ht_load_from_params(map { ($_, $req->upload($_)) } $req->upload);
is(ref($obj->upo), 'GLOB');

T->CDBI_Class->db_Main->begin_work;
$obj->cdbi_create_or_update;
T->CDBI_Class->db_Main->commit;
isnt($obj->class_dbi_object->v, undef);

T->CDBI_Class->db_Main->begin_work;
$res = $dbh->func($obj->class_dbi_object->v, "$td/b", 'lo_export');
T->CDBI_Class->db_Main->commit;
ok($res);

$res = read_file("$td/b");
@sres = HTML::Tested::ClassDBI::Upload->strip_mime_header($res);
is($sres[1], read_file("/bin/true"));
is($sres[0], 'application/octet-stream');

package T5;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV."::Upload", up1 => cdbi_upload => "v");
__PACKAGE__->ht_add_widget(::HTV."::Upload", up2 => cdbi_upload => "v");
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;
$req = HTML::Tested::Test::Request->new;
$req->add_upload(up2 => "$td/c.txt");

$obj = T5->ht_load_from_params(map { ($_, $req->upload($_)) } $req->upload);
is(ref($obj->up2), 'GLOB');

T->CDBI_Class->db_Main->begin_work;
$obj->cdbi_create_or_update;
T->CDBI_Class->db_Main->commit;
isnt($obj->class_dbi_object->v, undef);

my $str = read_file('/bin/cat');
T->CDBI_Class->db_Main->begin_work;
my $loid = HTML::Tested::ClassDBI::Upload->import_lo_from_string(
		T->CDBI_Class->db_Main, $str, 1);
isnt($loid, undef) or exit 1;
ok($dbh->func($loid, "$td/e", 'lo_export'));
T->CDBI_Class->db_Main->commit;

$res = read_file("$td/e");
@sres = HTML::Tested::ClassDBI::Upload->strip_mime_header($res);
is($sres[1], $str);
is($sres[0], 'application/octet-stream');

open(my $fh, '/bin/cat');
T->CDBI_Class->db_Main->begin_work;
$loid = HTML::Tested::ClassDBI::Upload->import_lo_object(
		T->CDBI_Class->db_Main, $fh, 1);
isnt($loid, undef) or exit 1;
ok($dbh->func($loid, "$td/e", 'lo_export'));
T->CDBI_Class->db_Main->commit;

$res = read_file("$td/e");
@sres = HTML::Tested::ClassDBI::Upload->strip_mime_header($res);
is($sres[1], $str);
is($sres[0], 'application/octet-stream');

T->CDBI_Class->db_Main->begin_work;
my ($lostr, $mime) = HTML::Tested::ClassDBI::Upload->export_lo_to_string(
			T->CDBI_Class->db_Main, $loid);
T->CDBI_Class->db_Main->commit;
is($mime, $sres[0]) or exit 1;
is(length $lostr, length $str);

T->CDBI_Class->db_Main->begin_work;
$loid = HTML::Tested::ClassDBI::Upload->import_lo_from_string(
		T->CDBI_Class->db_Main, $str);
isnt($loid, undef) or exit 1;
($lostr, $mime) = HTML::Tested::ClassDBI::Upload->export_lo_to_string(
			T->CDBI_Class->db_Main, $loid);
T->CDBI_Class->db_Main->commit;
is($mime, undef) or exit 1;
is(length $lostr, length $str);

eval {
($lostr, $mime) = HTML::Tested::ClassDBI::Upload->export_lo_to_string(
			T->CDBI_Class->db_Main, $loid);
};
isnt($@, '');

T->CDBI_Class->db_Main->begin_work;
my $loid2 = HTML::Tested::ClassDBI::Upload->import_lo_from_string(
		T->CDBI_Class->db_Main, [ "AA$str", $loid ]);
T->CDBI_Class->db_Main->commit;
is($loid2, $loid);

T->CDBI_Class->db_Main->begin_work;
($lostr, $mime) = HTML::Tested::ClassDBI::Upload->export_lo_to_string(
			T->CDBI_Class->db_Main, $loid2);
T->CDBI_Class->db_Main->commit;
is(length $lostr, length($str) + 2);

open($fh, '/bin/sh');
T->CDBI_Class->db_Main->begin_work;
my $loid3 = HTML::Tested::ClassDBI::Upload->import_lo_object(
		T->CDBI_Class->db_Main, [ $fh, $loid2 ], 1);
is($loid3, $loid2);
ok($dbh->func($loid, "$td/e2", 'lo_export'));
T->CDBI_Class->db_Main->commit;
isnt(-s "$td/e2", "$td/e");
chdir '/'
