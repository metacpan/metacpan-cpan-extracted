use strict;
use warnings FATAL => 'all';

use Test::More tests => 25;
use Test::TempDatabase;
use HTML::Tested qw(HTV);
use HTML::Tested::Value;
use HTML::Tested::Value::Link;
use Data::Dumper;

BEGIN { use_ok('HTML::Tested::ClassDBI'); }

my $tdb = Test::TempDatabase->create(dbname => 'ht_class_dbi_test',
		dbi_args => { RootClass => 'DBIx::ContextualFetch'
				, RaiseError => 1, PrintError => 0 });
my $dbh = $tdb->handle;
$dbh->do('SET client_min_messages TO error');

$dbh->do("create table table1 (a text not null, b text not null
		, c text not null, d text
		, constraint ab_uq unique(a, b))");

package CDBI_Base;
use base 'Class::DBI::Pg::More';

sub db_Main { return $dbh; }

package T1;
use base 'CDBI_Base';

__PACKAGE__->set_up_table('table1', { Primary => [ qw(a b) ] });

package HTC;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, $_ => cdbi_bind => "") for qw(a b c);


package main;
eval { HTC->bind_to_class_dbi('T1'); };
like($@, qr/Primary/);

HTC->bind_to_class_dbi('T1', { PrimaryKey => [ qw(a b) ] });
ok(1);

$dbh->do("insert into table1 (a, b, c) values ('1', '2', '3')");
my $obj = HTC->new({ a => "1", b => "2" });
isa_ok($obj->cdbi_retrieve, "T1");
isa_ok($obj->class_dbi_object, "T1");
is($obj->c, undef);

$obj->cdbi_load;
isnt($obj->c, undef);

my $scalar = "";
open(my $fh, "+>:scalar", \$scalar);
$dbh->trace(1, $fh);

$obj->cdbi_create_or_update({ d => "m" });
like($scalar, qr/SET\s+d = \?\s+WHERE/m);
is_deeply($dbh->selectcol_arrayref("select d from table1"), [ "m" ]);

$dbh->trace(0);
close $fh;

$scalar = "";
ok($obj->cdbi_create_or_update);

package HT2;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, $_ => cdbi_bind => "") for qw(a b c);
__PACKAGE__->bind_to_class_dbi('T1', { PrimaryKey => [] });

package main;
my $obj2 = HT2->new({ a => "1", b => "2" });
is($obj2->cdbi_retrieve, undef);

open($fh, "+>:scalar", \$scalar);
$dbh->trace(1, $fh);
$obj->cdbi_create_or_update;
$dbh->trace(0);
close $fh;
unlike($scalar, qr/SET/);

package HT3;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, $_ => cdbi_bind => "") for qw(b c);
__PACKAGE__->mk_accessors('a');
__PACKAGE__->bind_to_class_dbi('T1', { PrimaryKey => [ qw(a b) ] });

package main;

my $obj3 = HT3->new({ b => "2", a => "1" });
isa_ok($obj3->cdbi_load, 'T1');

$obj3 = HT3->new({ b => "2", a => "3", c => "4" });
isa_ok($obj3->cdbi_create_or_update, "T1");
is($obj3->c, 4);

$obj3->c("8");
ok($obj3->class_dbi_object);
$obj3->cdbi_update;

$obj3 = HT3->new({ b => "2", a => "3" });
$obj3->cdbi_load;
is($obj3->c, "8");

$obj3->ht_set_widget_option(c => cdbi_readonly => 1);
$obj3->c(5);
$obj3->cdbi_update;

$obj3 = HT3->new({ b => "2", a => "3" });
$obj3->cdbi_load;
is($obj3->c, "8");

package HT4;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, $_ => cdbi_bind => "") for qw(a b c d);
__PACKAGE__->bind_to_class_dbi('T1', { PrimaryKey => [ qw(a b) ] });

package main;

my $obj4 = HT4->new({ b => "2", a => "3", d => "dd" });
$obj4->cdbi_update;

$obj4 = HT4->new({ b => "2", a => "3" });
$obj4->cdbi_load;
is($obj4->c, "8");
is($obj4->d, "dd");

my $objs = HT4->query_class_dbi('retrieve_all');
is(@$objs, 2) or diag(Dumper($objs));

my @shells = (HT4->new({ b => "2", a => "3", d => "s1" })
	, HT4->new({ b => "2", a => "1", d => "s2" })
	, HT4->new({ b => "3", a => "3", d => "s3" }));
HT4->cdbi_set_many(\@shells, [ T1->retrieve_all ]);
is($shells[0]->class_dbi_object->c, 8);
is($shells[1]->class_dbi_object->c, 3);
is($shells[2]->class_dbi_object, undef);

# check undefined primary key
@shells = (HT4->new);
HT4->cdbi_set_many(\@shells, [ T1->retrieve_all ]);
is($shells[0]->class_dbi_object, undef);
