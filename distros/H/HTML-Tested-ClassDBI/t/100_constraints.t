use strict;
use warnings FATAL => 'all';
use Test::More tests => 12;

use Test::TempDatabase;
use Class::DBI;
use HTML::Tested qw(HTV);
use HTML::Tested::Value;
use Carp;

BEGIN { use_ok( 'HTML::Tested::ClassDBI' ); }

my $tdb = Test::TempDatabase->create(dbname => 'ht_class_dbi_test_2',
			dbi_args => { RootClass => 'DBIx::ContextualFetch' });
my $dbh = $tdb->handle;
$dbh->do('SET client_min_messages TO error');

$dbh->do("CREATE TABLE table1 (i1 serial primary key, "
		. "t1 text not null, t2 text, n1 integer, n2 smallint)");
is($dbh->{AutoCommit}, 1);

package CDBI_Base;
use base 'Class::DBI::Pg::More';

sub db_Main { return $dbh; }

package CDBI;
use base 'CDBI_Base';

__PACKAGE__->set_up_table('table1', { ColumnGroup => 'Essential' });

package main;

is(CDBI->autoupdate, undef);
my $c1 = CDBI->create({ t1 => 'a', t2 => 'b' });
ok($c1);
is($c1->i1, 1);

package HTC;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, 't1', cdbi_bind => '');
__PACKAGE__->ht_add_widget(::HTV, 't2', cdbi_bind => '');
__PACKAGE__->ht_add_widget(::HTV, 'n1', cdbi_bind => '');
__PACKAGE__->ht_add_widget(::HTV, 'n2', cdbi_bind => '');
__PACKAGE__->ht_add_widget(::HTV, 'ht_id', cdbi_bind => 'Primary');
__PACKAGE__->bind_to_class_dbi('CDBI');

package main;

my $o = HTC->new({ ht_id => 1 });
ok($o->cdbi_load);
is($o->t1, 'a');
is($o->t2, 'b');
is_deeply([ $o->ht_validate ], []);

$o->t1(undef);
is_deeply([ $o->ht_validate ], [ [ 't1', 'defined', '' ] ]);

$o = HTC->new({ t1 => 'c', t2 => 'd' });
# Primary should not validate - it can be empty on create
is_deeply([ $o->ht_validate ], []);

$o->n1('a');
$o->n2('b');
is_deeply([ $o->ht_validate ], [ [ n1 => 'integer' ], [ n2 => 'integer' ] ]);
