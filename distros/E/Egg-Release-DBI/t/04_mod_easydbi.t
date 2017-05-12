use Test::More;
use strict;
use warnings;
use lib qw( ../lib ./lib );
use Egg::Helper;
use Egg::Mod::EasyDBI { debug=> 0 };

# $ENV{EGG_DBI_DSN}       = 'dbi:Pg;:dbname=DATABASE';
# $ENV{EGG_DBI_USER}      = 'db_user';
# $ENV{EGG_DBI_PASSWORD}  = 'db_password';
# $ENV{EGG_DBI_TEST_TABLE}= 'egg_release_dbi_test';

eval{ require DBI };
if ($@) {
	plan skip_all=> "DBI is not installed."
} else {
	my $env= Egg::Helper->helper_get_dbi_attr;
	unless ($env->{dsn}) {
		plan skip_all=> "I want setup of environment variable.";
	} else {
		test($env);
	}
}

sub test {
plan tests=> 207;

my($dbi)= @_;
$dbi->{options}{AutoCommit}= 1;

ok my $dbh= DBI->connect(@{$dbi}{qw/ dsn user password options /}),
   q{my $dbh= DBI->connect(@{$dbi}{qw/ dsn user password options /})};

my $table= $dbi->{table};

eval {

ok $dbh->do(<<"END_ST"), qq{ CREATE TABLE $table };
CREATE TABLE $table (
  id     int2      primary key,
  uid    varchar,
  age    int4
  );
END_ST

ok my $es= Egg::Mod::EasyDBI->new($dbh, { trace=> 0 }),
   q{my $es= Egg::Mod::EasyDBI->new ...};

can_ok $es, 'dbh';
  isa_ok $dbh, 'DBI::db';

can_ok $es, 'commit_ok';
  ok $es->commit_ok(1), q{$es->commit_ok(1)};
  ok $es->commit_ok, q{$es->commit_ok};
  ok ! $es->commit_ok(0), q{! $es->commit_ok(0)};
  ok ! $es->commit_ok, q{! $es->commit_ok};

can_ok $es, 'rollback_ok';
  ok $es->rollback_ok(1), q{$es->rollback_ok(1)};
  ok $es->rollback_ok, q{$es->rollback_ok};
  ok ! $es->rollback_ok(0), q{! $es->rollback_ok(0)};
  ok ! $es->rollback_ok, q{! $es->rollback_ok};

can_ok $es, 'alias';
  isa_ok $es->alias, 'HASH';

can_ok $es, 'config';
  isa_ok $es->config, 'HASH';

can_ok $es, 'do';
  ok $es->do("INSERT INTO $table (id, uid, age) VALUES (?, ?, ?)", qw/ 1 foo 20 /),
     q{$es->do("INSERT INTO $table ...", ...)};

can_ok $es, 'scalarref';
  ok my $scalar= $es->scalarref("SELECT uid FROM $table WHERE age = ?", 20),
     q{my $scalar= $es->scalarref(SELECT uid FROM $table ...)};
  isa_ok $scalar, 'SCALAR';
  is $$scalar, 'foo', q{$$scalar, 'foo'};

can_ok $es, 'scalar';
  ok $scalar= $es->scalar("SELECT uid FROM $table WHERE age = ?", 20),
     q{$scalar= $es->scalarref(SELECT uid FROM $table ...)};
  is $scalar, 'foo', q{$scalar, 'foo'};

can_ok $es, 'hashref';
  ok my $hash= $es->hashref("SELECT * FROM $table WHERE uid = ?", 'foo'),
     q{my $hash= $es->hashref("SELECT * FROM $table ... )};
  isa_ok $hash, 'HASH';
  is $hash->{id}, 1, q{$hash->{id}, 1};
  is $hash->{uid}, 'foo', q{$hash->{uid}, 'foo'};
  is $hash->{age}, 20, q{$hash->{age}, 20};

can_ok $es, 'arrayref';
  ok my $array= $es->arrayref("SELECT * FROM $table WHERE uid = ?", 'foo'),
     q{my $array= $es->arrayref("SELECT * FROM $table ... )};
  isa_ok $array, 'ARRAY';
  isa_ok $array->[0], 'HASH';
  is $array->[0]{id}, 1, q{$array->[0]{id}, 1};
  is $array->[0]{uid}, 'foo', q{$array->[0]{uid}, 'foo'};
  is $array->[0]{age}, 20, q{$array->[0]{age}, 20};

can_ok $es, 'close';
  ok $es->close, q{$es->close};
  ok ! $es->dbh, q{! $es->dbh};

ok $es= Egg::Mod::EasyDBI->new($dbh, { trace=> 0, debug=> 1 }),
   q{my $es= Egg::Mod::EasyDBI->new ...};

can_ok $es, 'db';
  ok my $db= $es->db, q{my $db= $es->db};
  isa_ok $db, 'Egg::Mod::EasyDBI::db';
  ok my $obj= $db->$table, q{my $obj= $db->$table};
  isa_ok $obj, "Egg::Mod::EasyDBI::db::$table";
  isa_ok $obj, 'Egg::Mod::EasyDBI::table';

can_ok $obj, 'scalarref';
  ok ! $obj->scalarref('id', 'id = ?', 2000),
     q{! $obj->scalarref('id', 'id = ?', 2000)};
  ok $scalar= $obj->scalarref('id', 'uid = ?', 'foo'),
     q{$scalar= $obj->scalarref('id', 'uid = ?', 'foo')};
  isa_ok $scalar, 'SCALAR';
  ok $scalar= $obj->scalarref(\'id', 'uid = ?', 'foo'),
     q{$scalar= $obj->scalarref(\'id', 'uid = ?', 'foo')};
  isa_ok $scalar, 'SCALAR';

can_ok $obj, 'scalar';
  ok $scalar= $obj->scalar('id', 'age = 20'),
     q{$scalar= $obj->scalar('id', 'age = 20')};
  ok ! ref($scalar), q{! ref($scalar)};

can_ok $obj, 'insert';
  can_ok $obj, 'in';
  ok $obj->insert( id=> 2, uid=> 'hoge', age=> 18 ),
     q{$obj->insert( id=> 2, uid=> 'hoge', age=> 18 )};
  ok $obj->scalar('id', 'id = 2'),
     q{$obj->scalar('id', 'id = 2')};
  ok $obj->insert( id=> 3, uid=> ['hoge1', 'boo'], age=> 19 ),
     q{$obj->insert( id=> 3, uid=> ['hoge1', 'boo'], age=> 19 )};
  ok $obj->scalar('id', 'uid = ?', 'boo'),
     q{$obj->scalar('id', 'uid = ?', 'boo')};
  ok ! $obj->scalar('id', 'uid = ?', 'hoge1'),
     q{! $obj->scalar('id', 'uid = ?', 'hoge1')};
  ok $obj->insert( id=> 4, uid=> [[qw/ hoge1 hoge2 /], 'woo'], age=> 21 ),
     q{$obj->insert( id=> 4, uid=> [[qw/ hoge1 hoge2 /], 'woo'], age=> 21 )};
  ok $obj->scalar('id', 'uid = ?', 'woo'),
     q{$obj->scalar('id', 'uid = ?', 'woo')};
  ok ! $obj->scalar('id', 'uid = ?', 'hoge1'),
     q{! $obj->scalar('id', 'uid = ?', 'hoge1')};
  ok ! $obj->scalar('id', 'uid = ?', 'hoge2'),
     q{! $obj->scalar('id', 'uid = ?', 'hoge2')};
  ok $obj->insert( id=> 5, uid=> ['hoge1', \'poo'], age=> 22 ),
     q{$obj->insert( id=> 5, uid=> ['hoge1', \'poo'], age=> 22 )};
  ok $obj->scalar('id', 'uid = ?', 'poo'),
     q{$obj->scalar('id', 'uid = ?', 'poo')};
  ok $obj->insert( id=> 6, uid=> 'nana', age=> [22, 23] ),
     q{$obj->insert( id=> 6, uid=> 'nana', age=> [22, 23] )};
  ok $obj->scalar('id', 'uid = ? and age = ?', 'nana', 23),
     q{$obj->scalar('id', 'uid = ? and age = ?', 'nana', 23)};
  is $obj->scalar('count(id)'), 6, q{$obj->scalar('count(id)'), 6};

can_ok $obj, 'hashref';
  ok $hash= $obj->hashref('uid = ?', 'foo'),
     q{$hash= $obj->hashref('uid = ?', 'foo')};
  isa_ok $hash, 'HASH';
  is $hash->{id}, 1, q{$hash->{id}, 1};
  is $hash->{uid}, 'foo', q{$hash->{uid}, 'foo'};
  is $hash->{age}, 20, q{$hash->{age}, 20};
  ok $hash= $obj->hashref('uid = ? and age = ?', [qw/ foo 20 /]),
     q{$hash= $obj->hashref('uid = ? and age = ?', [qw/ foo 20 /])};
  isa_ok $hash, 'HASH';
  ok ! $obj->hashref('uid = ?', '12345'), q{! $obj->hashref('uid = ?', '12345')};
  ok $hash= $obj->hashref(\'id', 'uid = ?', 'foo'),
     q{$hash= $obj->hashref(\'id', 'uid = ?', 'foo')};
  ok $hash->{id}, q{$hash->{id}};
  ok ! $hash->{uid}, q{! $hash->{uid}};
  ok ! $hash->{age}, q{! $hash->{age}};
  ok $hash= $obj->hashref(\'id, uid', 'uid = ?', 'foo'),
     q{$hash= $obj->hashref(\'id, uid', 'uid = ?', 'foo')};
  ok $hash->{id}, q{$hash->{id}};
  ok $hash->{uid}, q{$hash->{uid}};
  ok ! $hash->{age}, q{! $hash->{age}};
  ok $hash= $obj->hashref, q{$hash= $obj->hashref};
  isa_ok $hash, 'HASH';
  ok $hash= $obj->hashref(['order by uid']),
     q{$hash= $obj->hashref(['order by uid'])};
  isa_ok $hash, 'HASH';

can_ok $obj, 'arrayref';
  can_ok $obj, 'list';
  ok $array= $obj->arrayref, q{$array= $obj->arrayref};
  isa_ok $array, 'ARRAY';
  isa_ok $array->[0], 'HASH';
  is scalar(@$array), 6, q{scalar(@$array), 6};
  ok $array->[0]{id}, q{$array->[0]{id}};
  ok $array->[0]{uid}, q{$array->[0]{uid}};
  ok $array->[0]{age}, q{$array->[0]{age}};
  ok $array= $obj->arrayref(\'id'), q{$array= $obj->arrayref(\'id')};
  ok $array->[0]{id}, q{$array->[0]{id}};
  ok ! $array->[0]{uid}, q{! $array->[0]{uid}};
  ok ! $array->[0]{age}, q{! $array->[0]{age}};
  ok $array= $obj->arrayref(\'id, uid'), q{$array= $obj->arrayref(\'id, uid')};
  ok $array->[0]{id}, q{$array->[0]{id}};
  ok $array->[0]{uid}, q{$array->[0]{uid}};
  ok ! $array->[0]{age}, q{! $array->[0]{age}};
  ok $array= $obj->arrayref('uid = ? or uid = ?', 'foo', 'boo'),
     q{$array= $obj->arrayref('uid = ? or uid = ?', 'foo', 'boo')};
  isa_ok $array, 'ARRAY';
  is scalar(@$array), 2, q{scalar(@$array), 2};
  ok $array= $obj->arrayref(\'id', 'uid = ? or uid = ?', 'foo', 'boo'),
     q{$array= $obj->arrayref(\'id', 'uid = ? or uid = ?', 'foo', 'boo')};
  isa_ok $array, 'ARRAY';
  is scalar(@$array), 2, q{scalar(@$array), 2};
  ok $array->[0]{id}, q{$array->[0]{id}};
  ok ! $array->[0]{uid}, q{! $array->[0]{uid}};
  ok ! $array->[0]{age}, q{! $array->[0]{age}};
  my $ok;
  ok $array= $obj->arrayref(\'id', 'uid = ? or uid = ?', ['foo', 'boo'], sub {
    my($array, %hash)= @_;
    isa_ok $array, 'ARRAY';
    ok $hash{id}, q{$hash{id}};
    ok ! $hash{uid}, q{! $hash{uid}};
    ok ! $hash{age}, q{! $hash{age}};
    push @$array, \%hash;
    ++$ok;
    }), q{$array= $obj->arrayref(\'id', 'uid = ? or uid = ?', ['foo', 'boo'], sub { .. })};
  is $ok, 2, q{$ok, 2};

can_ok $obj, 'update';
  ok $obj->update( uid=> 'foo', age=> 30 ),
     q{$obj->update( uid=> 'foo', age=> 30 )};
  ok $scalar= $obj->scalar('uid', 'age = 30'),
     q{$scalar= $obj->scalar('uid', 'age = 30')};
  is $scalar, 'foo', q{$scalar, 'foo'};
  ok $obj->update( age=> [30, 20] ),
     q{$obj->update( age=> [30, 20] )};
  ok $scalar= $obj->scalar('age', 'uid = ?', 'foo'),
     q{$scalar= $obj->scalar('age', 'uid = ?', 'foo')};
  is $scalar, 20, q{$scalar, 20};
  ok $scalar= $obj->scalar('age', 'id = 1'),
     q{$scalar= $obj->scalar('age', 'id = 1')};
  isnt $scalar, 30, q{! $scalar, 30};
  ok $scalar= $obj->scalar('age', 'id = 2'),
     q{$scalar= $obj->scalar('age', 'id = 2')};
  isnt $scalar, 30, q{! $scalar, 30};
  ok $obj->update(\'id = ? or id = ?', { id=> [[1, 2]], age=> 30 }, 'id'),
     q{$obj->update(\'id = ? or id = ?', { id=> [[1, 2]], age=> 30 }, 'id')};
  ok $scalar= $obj->scalar('age', 'id = 1'),
     q{$scalar= $obj->scalar('age', 'id = 1')};
  is $scalar, 30, q{$scalar, 30};
  ok $scalar= $obj->scalar('age', 'id = 2'),
     q{$scalar= $obj->scalar('age', 'id = 2')};
  is $scalar, 30, q{$scalar, 30};
  ok $scalar= $obj->scalar('count(id)', 'age = 30'),
     q{$scalar= $obj->scalar('count(id)', 'age = 30')};
  is $scalar, 2, q{$scalar, 2};
  ok $obj->update(\'age = ? or age = ?', age=> [[22, 23], 30] ),
     q{$obj->update(\'age = ? or age = ?', age=> [[22, 23], 30] )};
  ok $scalar= $obj->scalar('count(id)', 'age = 30'),
     q{$scalar= $obj->scalar('count(id)', 'age = 30')};
  is $scalar, 4, q{$scalar, 4};
  ok $obj->update( uid=> 'nana', age=> \"-8" ),
     q{$obj->update( uid=> 'nana', age=> \"-8" )};
  ok $scalar= $obj->scalar('count(id)', 'age = 30'),
     q{$scalar= $obj->scalar('count(id)', 'age = 30')};
  is $scalar, 3, q{$scalar, 3};
  ok $scalar= $obj->scalar('count(id)', 'age = 22'),
     q{$scalar= $obj->scalar('count(id)', 'age = 22')};
  is $scalar, 1, q{$scalar, 1};
  ok $obj->update( age=> ['30', \1] ),
     q{$obj->update( age=> ['30', \1] )};
  ok ! $obj->scalar('count(id)', 'age = 30'),
     q{! $obj->scalar('count(id)', 'age = 30')};
  ok $scalar= $obj->scalar('count(id)', 'age = 31'),
     q{$scalar= $obj->scalar('count(id)', 'age = 31')};
  is $scalar, 3, q{$scalar, 3};
  ok $obj->update(\'uid = ? and age = ?', uid => 'poo', age=> [31, 23] ),
     q{$obj->update(\'uid = ? and age = ?', uid => 'poo', age=> [31, 23] )};
  ok $scalar= $obj->scalar('age', 'uid = ?', 'poo'),
     q{$scalar= $obj->scalar('age', 'uid = ?', 'poo')};
  is $scalar, 23, q{$scalar, 23};
  ok $obj->update(\'uid like ?', uid=> ['%poo%',{}], age=> 25),
     q{$obj->update(\'uid like ?', uid=> ['%poo%',{}], age=> 25)};
  ok $obj->update(\'age > ? and age < ?', age=> [[24, 26], 23] ),
     q{$obj->update(\'age > ? and age < ?', age=> [[24, 26], 23] )};

can_ok $obj, 'update_insert';
  ok $obj->update_insert(\'uid = ?', id=> 7, uid=> 'oz', age=> 25),
     q{$obj->update_insert(\'uid = ?', id=> 7, uid=> 'oz', age=> 25)};
  is $obj->scalar('count(id)'), 7, q{$obj->scalar('count(id)'), 7};

can_ok $obj, 'find_insert';
  ok $obj->find_insert( uid=> 'goo', id=> 8, age=> 26 ),
     q{$obj->find_insert( uid=> 'goo', id=> 8, age=> 26 )};
  is $obj->scalar('count(id)'), 8, q{$obj->scalar('count(id)'), 8};
  ok $obj->find_insert('uid', id=> 9, uid=> 'hee', age=> 27 ),
     q{$obj->find_insert('uid', id=> 9, uid=> 'hee', age=> 27 )};
  is $obj->scalar('count(id)'), 9, q{$obj->scalar('count(id)'), 9};
  ok $obj->find_insert('uid', { id=> 10, uid=> 'zoo', age=> 28 }),
     q{$obj->find_insert('uid', { id=> 10, uid=> 'zoo', age=> 28 })};
  is $obj->scalar('count(id)'), 10, q{$obj->scalar('count(id)'), 10};

can_ok $obj, 'for_update';
#  ok $obj->for_update( uid => 'foo' ), q{$obj->for_update};

can_ok $obj, 'delete';
  ok $obj->delete('uid = ?', 'zoo'), q{$obj->delete('uid = ?', 'zoo')};
  is $obj->scalar('count(id)'), 9, q{$obj->scalar('count(id)'), 9};
  ok $obj->delete(\'uid = ?', 'hee'), q{$obj->delete('uid = ?', 'hee')};
  is $obj->scalar('count(id)'), 8, q{$obj->scalar('count(id)'), 8};
  ok $obj->delete('id = 7'), q{$obj->delete('id = 7')};
  is $obj->scalar('count(id)'), 7, q{$obj->scalar('count(id)'), 7};

can_ok $obj, 'upgrade';
  eval{ $obj->upgrade( age=> 26 ) };
  ok $@, q{! $obj->upgrade( age=> 26 ) };
  can_ok $es, 'upgrade_ok';
  ok $es->upgrade_ok(1), q{$es->upgrade_ok(1)};
  ok $obj->upgrade( age=> 26 ), q{$obj->upgrade( age=> 26 )};
  $ok= 0;
  ok $obj->arrayref(undef, undef, sub {
  	my($array, %hash)= @_;
  	++$ok if $hash{age}== 26;
  	push @$array, \%hash;
    }), q{$obj->arrayref(undef, undef, sub { ... }) };
  is $ok, 7, q{$ok, 7};

can_ok $obj, 'clear';
  eval{ $obj->clear };
  ok $@, q{! $obj->clear };
  can_ok $es, 'clear_ok';
  ok $es->clear_ok(1), q{$es->clear_ok(1)};
  ok $obj->clear, q{$obj->clear};
  is $obj->scalar('count(id)'), 0, q{$obj->scalar('count(id)'), 0};

ok my $j= $es->db(qw/ test1 = test2:a.id=b.id < test3:b.id=c.id > test4:c.id=d.id /),
   q{my $j= $es->db(qw/ test1 = test2 ..... };
  isa_ok $j, 'Egg::Mod::EasyDBI::joindb';
  isa_ok $j->[1], 'Egg::Mod::EasyDBI';
  like $j->[0], qr{^test1 a}, q{$j->[0], qr{^test1 a}};
  like $j->[0], qr{\s+JOIN\s+test2\s+b\s+ON\s+a\.id\s*\=\s*b\.id},
     q{$j->[0], qr{\s+JOIN\s+test2\s+b\s+ON\s+a\.id\s*\=\s*b\.id}};
  like $j->[0], qr{\s+LEFT\s+OUTER\s+JOIN\s+test3\s+c\s+ON\s+b\.id\s*\=\s*c\.id},
     q{$j->[0], qr{\s+LEFT\s+OUTER\s+JOIN\s+test3\s+c\s+ON\s+b\.id\s*\=\s*c\.id}};
  like $j->[0], qr{\s+RIGHT\s+OUTER\s+JOIN\s+test4\s+d\s+ON\s+c\.id\s*\=\s*d\.id},
     q{$j->[0], qr{\s+RIGHT\s+OUTER\s+JOIN\s+test4\s+d\s+ON\s+c\.id\s*\=\s*d\.id}};

  };

$@ and warn $@;

ok $dbh->do(qq{ DROP TABLE $dbi->{table} }), qq{ DROP TABLE $dbi->{table} };

}
