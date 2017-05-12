use strict;
use warnings FATAL => 'all';

use Test::More tests => 22;
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

$dbh->do("CREATE TABLE table1 (id serial primary key
		, t1 text not null, t2 text not null unique)");

my @_cdbi_traces;

# $SIG{__DIE__} = sub { diag(Carp::longmess(@_)); };
package CDBI_Base;
use base 'Class::DBI::Pg::More';

sub db_Main { return $dbh; }

package T1;
use base 'CDBI_Base';

__PACKAGE__->set_up_table('table1', { ColumnGroup => 'Essential' });

sub get {
	my $lm = Carp::longmess();
	push @_cdbi_traces, $lm unless $lm =~ /(cdbi_create)/;
	return shift()->SUPER::get(@_);
}

package HTC;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, t2 => cdbi_bind => "", cdbi_primary => 1);
__PACKAGE__->ht_add_widget(::HTV, t1 => cdbi_bind => "");
__PACKAGE__->bind_to_class_dbi('T1');

package main;

my $t1 = T1->create({ t1 => "moo", t2 => "foo" });

my $h = HTC->new({ t2 => "foo" });
is($h->t2, "foo");

my $obj = $h->cdbi_load;
is($obj->id, $t1->id);
is($h->t2, "foo");
is($h->t1, "moo");

package HTC2;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, id => cdbi_bind => "Primary");
__PACKAGE__->ht_add_widget(::HTV, t2 => cdbi_bind => "");
__PACKAGE__->ht_add_widget(::HTV, t1 => cdbi_bind => "");
__PACKAGE__->bind_to_class_dbi('T1');

package main;

my $h2 = HTC2->new({ t2 => "foo", t1 => "moo" });
eval { $h2->cdbi_create };
like($@, qr/moo/);
like($@, qr/unique/);

$h2->t2("gu");
isnt($h2->cdbi_create, undef);

$h2->t2("foo");
eval { $h2->cdbi_update; };
like($@, qr/moo/);
like($@, qr/unique/);

$h2->t2("du");
isnt($h2->cdbi_update, undef);

$h = HTC->new({ t2 => "du" });
isnt($h->cdbi_load, undef);
is($h->t1, "moo");
$h->t1("kok");
isnt($h->cdbi_update, undef);
is($h2->ht_get_widget_option(t2 => 'cdbi_column_info')->{type}, "text");
is($h2->ht_get_widget_option(id => 'cdbi_readonly'), 1);

package HTC3;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV, id => cdbi_bind => "Primary"
		, cdbi_readonly => undef);
__PACKAGE__->bind_to_class_dbi('T1');

package main;
is(HTC3->ht_get_widget_option(id => 'cdbi_readonly'), undef);
is($h2->ht_get_widget_option(id => 'cdbi_column_info')->{type}, "integer");

package HTC4;
use base 'HTML::Tested::ClassDBI';
__PACKAGE__->ht_add_widget(::HTV."::Link", 'l', caption => "L"
	, href_format => '../l?id=%s', cdbi_bind => [ 'Primary' ]);
__PACKAGE__->bind_to_class_dbi('T1');

package main;

my $htc4 = HTC4->new;
is_deeply([ $htc4->ht_validate ], []);

# get_column_value is too performance critical to call into Class::DBI
# for updates
unlike(join("\n", @_cdbi_traces), qr/get_column_value/);

$h = HTC->new({ t2 => "du", t1 => 'ggg' });
isnt($h->cdbi_load, undef);
is($h->t1, 'kok');
