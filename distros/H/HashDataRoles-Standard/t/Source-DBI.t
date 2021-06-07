#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use DBI;
use File::Temp qw(tempfile);
use HashData::DBI;

my ($tempfh, $tempfile) = tempfile();
my $dbh = DBI->connect("dbi:SQLite:dbname=$tempfile", undef, undef, {RaiseError=>1});
$dbh->do("CREATE TABLE t (k TEXT PRIMARY KEY, v TEXT)");
$dbh->do("INSERT INTO t VALUES ('one', 'satu')");
$dbh->do("INSERT INTO t VALUES ('two', 'dua')");
$dbh->do("INSERT INTO t VALUES ('three', 'tiga')");

# XXX test accept dsn, user, password instead of dbh
# XXX test accept iterate_sth & get_by_key_sth & row_count_sth
# XXX test accept dbh, query, key_column, val_column_row_count_query

my $t = HashData::DBI->new(dbh=>$dbh, table=>'t', key_column=>'k', val_column=>'v');

$t->reset_iterator;
is_deeply($t->get_next_item, ['one','satu']);
is_deeply($t->get_next_item, ['two','dua']);
$t->reset_iterator;
is_deeply($t->get_next_item, ['one','satu']);
is($t->get_item_count, 3);

ok($t->has_item_at_key('two'));
is_deeply($t->get_item_at_key('two'), 'dua');
ok(!$t->has_item_at_key('four'));
dies_ok { $t->get_item_at_key('four') };

ok($t->has_item_at_pos(0));
is_deeply($t->get_item_at_pos(0), ['one','satu']);
ok(!$t->has_item_at_pos(3));
dies_ok { $t->get_item_at_pos(3) };

done_testing;
