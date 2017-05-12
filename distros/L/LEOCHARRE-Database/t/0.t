use Test::Simple 'no_plan';
use warnings;
use strict;
use lib './lib';
use lib './t';
use Test;
use Cwd;



my $abs_db = cwd().'/t/test.db';
unlink $abs_db ;#if -f $abs_db;


if( -f  $abs_db ){
   ok(1," $abs_db existed.. deleting");
   unlink $abs_db;
   ok(! -f  $abs_db,'deleted');
}




my $i = new Test({ DBABSPATH => $abs_db });



ok($i,'Test.pm instanced');

ok($i->dbh,'returns dbh');
#$i->dbh->commit;
#ok( -f $abs_db, " file $abs_db exists");




my $driver = $i->dbh_driver;

print STDERR " # driver is $driver\n";


ok( $i->dbh_driver,'dbh_driver returns defined value');


ok($i->dbh_is_sqlite,'dbh_is_sqlite()');

ok( ! $i->dbh_is_mysql,'dbh is not mysql');
ok( $i->dbh->commit, 'dbh commit');


$i->dbh->{RaiseError}=0;
$i->dbh->{PrintError}=0;




   $i->dbh->do(
      'CREATE TABLE stuff ( name varchar(34), quantity integer(10) )'
   ) 
    #or die(" failed create: [$DBI::errstr]");
    ;





ok( $i->dbh_sth('INSERT INTO stuff (name) values (?)'),'dbh_sth returns');


my $ins = $i->dbh_sth('INSERT INTO stuff (name,quantity) values (?,?)');


ok(defined $ins, 'ins defined') or die;

$ins->execute('mice',34);
$ins->execute('dogs',22);



ok( $i->dbh_count('SELECT COUNT(*) FROM stuff') == 2 , 'dbh-count returns 2');

$ins->execute('cats',5);

ok( $i->dbh_count('SELECT COUNT(*) FROM stuff') == 3 , 'dbh-count returns 3 after insert');



$ins->execute('hamsters',5);

my $lid = $i->dbh_lid('stuff');
ok($lid, 'dbh_lid');


my $names = $i->dbh_selectcol('SELECT name FROM stuff');

## $names


ok( scalar @$names == 4 ,'dbh_selectcol');






 
