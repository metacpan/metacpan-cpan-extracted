use strict;
use warnings FATAL => 'all';
use Test::More tests => 43;

use Test::TempDatabase;
use Carp;
use Data::Dumper;
use HTML::Tested qw(HTV);
use HTML::Tested::Value;

BEGIN { use_ok('HTML::Tested::ClassDBI'); }

# $SIG{__DIE__} = sub { diag(Carp::longmess(@_)); };
my $tdb = Test::TempDatabase->create(dbname => 'ht_class_dbi_test',
		dbi_args => { RootClass => 'DBIx::ContextualFetch' });
my $dbh = $tdb->handle;
$dbh->do('SET client_min_messages TO error');
$dbh->do(<<ENDS);
create table table1 (id1 serial primary key, t1 text not null);
create table table2 (id2 serial primary key, t2 text not null);
ENDS

package CDBI_Base;
use base 'Class::DBI::Pg::More';

sub db_Main { return $dbh; }

package T1;
use base 'CDBI_Base';

__PACKAGE__->set_up_table('table1');

package T2;
use base 'CDBI_Base';

__PACKAGE__->set_up_table('table2');

package HTC;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 'id1', cdbi_bind => 'Primary');
__PACKAGE__->ht_add_widget(::HTV, 't1', cdbi_bind => '');
__PACKAGE__->ht_add_widget(::HTV, 'id2', cdbi_bind => 'Primary'
		, cdbi_group => 'g2');
__PACKAGE__->ht_add_widget(::HTV, 't2', cdbi_bind => ''
		, cdbi_group => 'g2');
__PACKAGE__->bind_to_class_dbi('T1');
__PACKAGE__->bind_to_class_dbi_gr('g2', 'T2');

package main;

my $obj = HTC->new();
is($obj->class_dbi_object_gr('g2'), undef);
$obj->class_dbi_object_gr('g2', 'ggg');
is($obj->class_dbi_object_gr('g2'), 'ggg');
$obj->class_dbi_object_gr('g2', undef);
is($obj->class_dbi_object_gr('g2'), undef);

$obj->t2('te 2');
my $co = $obj->cdbi_create_gr('g2');
isa_ok($co, 'T2');

my $arr = $dbh->selectall_arrayref("select id2, t2 from table2");
is_deeply($arr, [ [ 1, 'te 2' ] ]);
is_deeply($obj->class_dbi_object_gr('g2'), $co);
is($obj->t2, 'te 2');
is($obj->id2, 1);

$obj = HTC->new();
$obj->t1('t 1');
$obj->t2('t 2');
$co = $obj->cdbi_create;
isa_ok($co, 'T1');
$arr = $dbh->selectall_arrayref("select id2, t2 from table2");
is_deeply($arr, [ [ 1, 'te 2' ], [ 2, 't 2' ] ]);

$arr = $dbh->selectall_arrayref("select id1, t1 from table1");
is_deeply($arr, [ [ 1, 't 1' ] ]);
is($obj->id1, 1);
is($obj->id2, 2);

$obj->t2('y 2');
$co = $obj->cdbi_update_gr('g2');
is($co->t2, 'y 2');
$arr = $dbh->selectall_arrayref("select id2, t2 from table2");
is_deeply($arr, [ [ 1, 'te 2' ], [ 2, 'y 2' ] ]);

$obj = HTC->new({ id2 => 1 });
$co = $obj->cdbi_retrieve_gr('g2');
is($co->t2, 'te 2');
is_deeply($obj->class_dbi_object_gr('g2'), $co);

$obj = HTC->new({ id2 => 1, t2 => 'b 2' });
$obj->cdbi_update_gr('g2');
$arr = $dbh->selectall_arrayref("select id2, t2 from table2 order by id2");
is_deeply($arr, [ [ 1, 'b 2' ], [ 2, 'y 2' ] ]);

$obj = HTC->new({ id2 => 1, t2 => 'c 2', id1 => 1, t1 => 'c 1' });
$co = $obj->cdbi_update;
is($co->t1, 'c 1');
$arr = $dbh->selectall_arrayref("select id2, t2 from table2 order by id2");
is_deeply($arr, [ [ 1, 'c 2' ], [ 2, 'y 2' ] ]);
$arr = $dbh->selectall_arrayref("select id1, t1 from table1");
is_deeply($arr, [ [ 1, 'c 1' ] ]);
$co = $obj->class_dbi_object_gr('g2');
is($co->t2, 'c 2');

$obj = HTC->new({ id2 => 1, id1 => 1 });
$co = $obj->cdbi_retrieve;
is($co->t1, 'c 1');
is_deeply($obj->class_dbi_object, $co);
$co = $obj->class_dbi_object_gr('g2');
is($co->t2, 'c 2');

$obj = HTC->new({ id2 => 1, t2 => 't 2' });
$obj->cdbi_create_or_update_gr('g2');
$arr = $dbh->selectall_arrayref("select id2, t2 from table2 order by id2");
is_deeply($arr, [ [ 1, 't 2' ], [ 2, 'y 2' ] ]);

$obj->id2(undef);
$obj->t2('x 2');
$obj->cdbi_create_or_update_gr('g2');
$arr = $dbh->selectall_arrayref("select id2, t2 from table2 order by id2");
is_deeply($arr, [ [ 1, 'x 2' ], [ 2, 'y 2' ] ]);

$obj = HTC->new({ t2 => 'c 2', id1 => 1, t1 => 'x 1' });
$obj->cdbi_create_or_update;
$arr = $dbh->selectall_arrayref("select id2, t2 from table2 order by id2");
is_deeply($arr, [ [ 1, 'x 2' ], [ 2, 'y 2' ], [ 3, 'c 2' ] ]);
$arr = $dbh->selectall_arrayref("select id1, t1 from table1");
is_deeply($arr, [ [ 1, 'x 1' ] ]);

$obj = HTC->new({ id2 => 3 });
$co = $obj->cdbi_construct_gr('g2');
isa_ok($co, 'T2');

$obj = HTC->new({ id2 => 3 });
$obj->cdbi_delete_gr('g2');
$arr = $dbh->selectall_arrayref("select id2, t2 from table2 order by id2");
is_deeply($arr, [ [ 1, 'x 2' ], [ 2, 'y 2' ] ]);

$obj = HTC->new({ id2 => 1 });
isa_ok($obj->cdbi_load_gr('g2'), 'T2');
is($obj->t2, 'x 2');
isa_ok($obj->class_dbi_object_gr('g2'), 'T2');

$obj = HTC->new({ id2 => 1, id1 => 1 });
isa_ok($obj->cdbi_load, 'T1');
is($obj->t2, 'x 2');
is($obj->t1, 'x 1');
isa_ok($obj->class_dbi_object_gr('g2'), 'T2');

$co = $obj->cdbi_construct_gr('g2');
$obj = HTC->new({ id1 => 1 });
$obj->class_dbi_object_gr('g2', $co);
$obj->cdbi_load;
is($obj->t2, 'x 2');
is($obj->t1, 'x 1');

$obj = HTC->new({ id1 => 1, id2 => 1 });
$obj->cdbi_update({ t1 => 'foo', t2 => 'moo' });
is($obj->t2, 'moo');
is($obj->t1, 'foo');
