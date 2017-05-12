use strict;
use warnings FATAL => 'all';
use Test::More tests => 17;

use Test::TempDatabase;
use HTML::Tested qw(HTV);
use HTML::Tested::Seal;
use HTML::Tested::Value::Marked;
use Data::Dumper;
use HTML::Tested::Test;

BEGIN { use_ok('HTML::Tested::ClassDBI'); }

HTML::Tested::Seal->instance('boo boo boo');

my $tdb = Test::TempDatabase->create(dbname => 'ht_class_dbi_test',
		dbi_args => { RootClass => 'DBIx::ContextualFetch'
			, RaiseError => 1, PrintError => undef });
my $dbh = $tdb->handle;
$dbh->do('SET client_min_messages TO error');
$dbh->do("CREATE TABLE table1 (id serial primary key, t1 text not null)");

$dbh->do("insert into table1 (t1) values (?)", undef, 'дед');
is_deeply($dbh->selectcol_arrayref("select t1 from table1"), [ 'дед' ]);

package CDBI_Base;
use base 'Class::DBI::Pg::More';

sub db_Main { return $dbh; }

package CDBI;
use base 'CDBI_Base';

__PACKAGE__->set_up_table('table1', { ColumnGroup => 'Essential' });

package HTC;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV."::Marked", 't1', cdbi_bind => '');
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;

my $object = HTC->new({ id => 1 });
ok($object->cdbi_load);
is($object->t1, 'дед');

my $stash = {};
$object->ht_render($stash);
is($stash->{t1}, '<!-- t1 --> дед');
is_deeply([ HTML::Tested::Test->check_stash(ref($object), 
		$stash, { HT_SEALED_id => 1, t1 => 'дед' }) ], []);

package H2;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;
my $obj = H2->new({ id => 100 });
$obj->cdbi_create_or_update({ t1 => 'hi' });
is($obj->class_dbi_object->t1, 'hi');

$obj->class_dbi_object(undef);
$obj->cdbi_update({ t1 => "moo" });
is($obj->class_dbi_object->t1, 'moo');

package H3;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV, 't1', cdbi_bind => '', cdbi_readonly => 1);
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;
$obj = H3->new({ id => 100 });
$obj->cdbi_load;
is($obj->class_dbi_object->t1, 'moo');
is($obj->t1, 'moo');
$obj->t1(undef);

# readonly should not validate
is_deeply([ $obj->ht_validate ], []);

$obj->cdbi_update;
is($obj->class_dbi_object->t1, 'moo');
is($obj->t1, 'moo');

$obj = H3->new({ id => 200 });
eval { $obj->cdbi_update; };
like($@, qr/Nothing/);

$object->t1("foo");
$object->cdbi_update;
ok(1, "object has nothing to do with obj. Here we are ok");

$object = HTC->new({ id => 1 });
ok($object->cdbi_load);
is($object->t1, 'foo');
