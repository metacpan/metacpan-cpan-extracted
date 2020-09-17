#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use Iterator::Records;
use Data::Dumper;

eval "use DBI;";
if ($@) {
   plan skip_all => "DBI is required for database integration; skipping tests";
} else {
   eval "use DBD::SQLite;";
   if ($@) {
      plan skip_all => "SQLite is used to test database integration; skipping tests";
   } else {

my $i;

my $dbh = Iterator::Records::db->open(); # open an in-memory SQLite database
$dbh->do(<<EOF);
create table test_table (
  foo text,
  bar text
);
EOF
my $sth = $dbh->prepare ("insert into test_table values (?, ?)");
$sth->execute('a', 'b');
$sth->execute('c', 'd');

my $data = $dbh->select ("select * from test_table");
is_deeply ($data, [['a', 'b'], ['c', 'd']], 'basic retrieval');

is ($dbh->get ("select bar from test_table where foo=?", 'a'), 'b', 'get one value');
is_deeply ($dbh->select_one ("select * from test_table where foo=?", 'c'), ['c', 'd'], 'get one row');

$i = $dbh->iterator ("select * from test_table");
is_deeply($i->fields(), ['foo', 'bar'], 'fields defined correctly');
my $ii = $i->iter();
is_deeply ($ii->(), ['a', 'b'], 'first row retrieved');
is_deeply ($ii->(), ['c', 'd'], 'second row retrieved');
my $r = $ii->();
ok (not defined $r);
is_deeply ($i->load(), [['a', 'b'], ['c', 'd']], 'second run through iterator');

# Let's do a parameterized query now.
$i = $dbh->itparms ("select * from test_table where foo=?", ['foo', 'bar']);
$ii = $i->iter('a');
is_deeply($ii->(), ['a', 'b']);
$r = $ii->();
ok (not defined $r);
$ii = $i->iter('c');
is_deeply($ii->(), ['c', 'd']);
$r = $ii->();
ok (not defined $r);

# And just for completeness, let's load a parameterized query.
is_deeply ($i->load_parms('a'), [['a', 'b']]);

# Now some bulk loads.
$dbh->do("delete from test_table");
my $count = $dbh->load_table ('test_table', Iterator::Records->new ([['b', 'a'], ['d', 'c']], ['foo', 'bar']));
is ($count, 2, 'two rows loaded');
is ($dbh->get ("select bar from test_table where foo=?", 'b'), 'a', 'check first value after load');
is ($dbh->get ("select bar from test_table where foo=?", 'd'), 'c', 'check first value after load');

$dbh->do("delete from test_table");
$count = $dbh->load_sql ('insert into test_table values (?, ?)', [['b', '1'], ['d', '2']]);
is ($count, 2, 'two rows loaded');
is ($dbh->get ("select bar from test_table where foo=?", 'b'), '1', 'check first value after load');
is ($dbh->get ("select bar from test_table where foo=?", 'd'), '2', 'check first value after load');



#diag (Dumper($i));
#diag($i->load());


done_testing();

   }
}

