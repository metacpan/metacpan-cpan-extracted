use Test::Simple 'no_plan';
use warnings;
use strict;
use lib './lib';

use DBI;
use base 'LEOCHARRE::Database::Base';

use Cwd;

my $abs_db = cwd().'/t/test.db';
unlink $abs_db if -f $abs_db;

ok( !-f $abs_db,' abs db is not there and will recreate');

my $dbh = DBI::connect_sqlite($abs_db);




#my $dbh = DBI::connect_mysql( dbname, dbuser, dbpass);



ok($dbh,'connect_sqlite() handle returned') or die('cannot get a dbh handle');



# driver

my $driver = $dbh->driver;
ok($driver, 'driver() returns');
print STDERR " # driver is $driver\n";
ok( $dbh->is_sqlite,'is_sqlite()');
ok( ! $dbh->is_mysql,'! is_mysql');



# table
ok( ! $dbh->table_exists('stuff'),'! table_exists() stuff');
ok( $dbh->do('CREATE TABLE stuff ( name varchar(34), quantity integer(10) )'),'created table');
ok( $dbh->table_exists('stuff'),'table_exists() stuff');



# insert


my $ins;
ok( $ins = $dbh->prepare('INSERT INTO stuff (name,quantity) values (?,?)'),
   'insert prepared');


ok( $dbh->rows_count('SELECT COUNT(*) FROM stuff') == 0 , 'rows_count() returns 0');

ok( $ins->execute('mice',34));
ok( $ins->execute('dogs',22));



ok( $dbh->rows_count('SELECT COUNT(*) FROM stuff') == 2 , 'rows_count() returns 2');

$ins->execute('cats',5);

ok( $dbh->rows_count('SELECT COUNT(*) FROM stuff') == 3 , 'rows_count() returns 3 after insert');



$ins->execute('hamsters',5);

my $lid = $dbh->lid('stuff');
ok($lid, 'dbh->lid');
ok($lid == 4, 'lid is 4');

ok($dbh->lid('stuff') == 4, 'lid is still 4');



ok( $dbh->do('CREATE TABLE stuff2 ( name varchar(34), quantity integer(10) )'),'created table');
my $ins2;
ok( $ins2 = $dbh->prepare('INSERT INTO stuff2 (name,quantity) values (?,?)'),
   'insert2 prepared');

$ins2->execute('cars',4);
ok( $dbh->rows_count('SELECT COUNT(*) FROM stuff2') == 1 , 'rows_count() returns 1 for table cars' );
ok( $dbh->rows_count('stuff2') == 1 , 'rows_count() with only tablename arg returns 1 for table cars' );






my $names = $dbh->selectcol('SELECT name FROM stuff');
ok($names,"selectcol() returns ");

## $names


ok( scalar @$names == 4 ,'selectcol() count is as expected');




my $dump = $dbh->table_dump('stuff');
ok($dump, 'table_dump() returns string');
print STDERR "$dump\n\n";
 

my $dump2 = $dbh->table_dump('stuff2');
ok($dump2, 'table_dump() returns string 2');
print STDERR "$dump2\n\n";


 
