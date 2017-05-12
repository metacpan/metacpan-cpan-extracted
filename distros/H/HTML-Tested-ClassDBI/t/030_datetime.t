use strict;
use warnings FATAL => 'all';
use Test::More tests => 17;

use Test::TempDatabase;
use HTML::Tested qw(HTV);
use HTML::Tested::Value;
use HTML::Tested::Value::Marked;
use HTML::Tested::Value::Link;

BEGIN { use_ok('HTML::Tested::ClassDBI'); }

my $tdb = Test::TempDatabase->create(dbname => 'ht_class_dbi_test',
		dbi_args => { RootClass => 'DBIx::ContextualFetch' });

my $dbh = $tdb->handle;
$dbh->do('SET client_min_messages TO error');

$dbh->do("CREATE TABLE table1 (id serial primary key, d1 date not null)");
$dbh->do("CREATE TABLE table2 (id serial primary key
		, t1 timestamp not null, t2 time not null)");

HTML::Tested::Seal->instance('boo boo boo');

package CDBI_Base;
use base 'Class::DBI::Pg::More';

sub db_Main { return $dbh; }

package T1;
use base 'CDBI_Base';

__PACKAGE__->set_up_table('table1', { ColumnGroup => 'Essential' });

package HTC;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary'
		, is_sealed => undef);
__PACKAGE__->ht_add_widget(::HTV."::Marked", 'd1', cdbi_bind => '');
__PACKAGE__->bind_to_class_dbi('T1');

package main;

my $dt = DateTime->new(year => 1975, month => 5, day => 6);
my $t1 = T1->create({ d1 => $dt });
isnt($t1, undef);
is($t1->id, 1);

my $o = HTC->new({ id => 1 });
ok($o->cdbi_load);
is($o->d1->month, 5);

my $stash = {};
$o->ht_render($stash);
is_deeply($stash, { id => 1, d1 => '<!-- d1 --> May 6, 1975' });

$o->id(undef);
$o->d1(DateTime->new(year => 1975, month => 7, day => 6));
$o->cdbi_create;

my $t2 = T1->retrieve(2);
isnt($t2, undef) or exit 1;
is($t2->d1->month, 7);
is($o->id, 2);
is($o->d1->month, 7);

package T2;
use base 'CDBI_Base';
__PACKAGE__->set_up_table('table2', { ColumnGroup => 'Essential' });

package H2;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary'
		, is_sealed => undef);
__PACKAGE__->ht_add_widget(::HTV."::Link", lnk => cdbi_bind => [ 't1', 't2' ]);
__PACKAGE__->bind_to_class_dbi('T2');

package main;

my $dt1 = DateTime->new(year => 1975, month => 5, day => 6
		, hour => 13, minute => 45);
my $dt2 = DateTime->new(year => 1975, month => 4, day => 3
				, hour => 14, minute => 40);
my $t22 = T2->create({ t1 => $dt1, t2 => $dt2 });
isnt($t22, undef);
is($t22->id, 1);
is($t22->t1->hour, 13);
is($t22->t2->hour, 14);

T2->columns(TEMP => "hi");
T2->set_sql(with_hi => "select __ESSENTIAL__, 12 as hi from __TABLE__");

package H3;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV, 'hi', cdbi_bind => '');
__PACKAGE__->bind_to_class_dbi('T2');

package main;
my $h3_res = H3->query_class_dbi('search_with_hi');
is($h3_res->[0]->hi, 12);

package H4;
use base 'H3';
__PACKAGE__->ht_add_widget(::HTV, 'h3', cdbi_bind => 2);

package H5;
use base 'H3';
__PACKAGE__->ht_add_widget(::HTV, 'h3', cdbi_bind => [ 2 ]);

package main;

eval { H4->bind_to_class_dbi('T2'); };
like($@, qr/h3.*column/);

eval { H5->bind_to_class_dbi('T2'); };
like($@, qr/h3.*column/);
