#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 25 } ;

use HDB ;

use strict ;
use warnings qw'all' ;

my $test_db = "./testsqlite.db" ;

#########################
{
  
  HDB::REQUIRE() ;
  
  sub parse { &HDB::Parser::Parse_Where } ;

  ok(
  parse(q`NAME == ANDRE LIMA and (x == 1 || x =2)`) ,
  q`WHERE( NAME = "ANDRE LIMA" AND (x = 1 OR x = 2)  )`
  ) ;
  
  ok(
  parse(q`NAME == ANDRE LIMA`) ,
  q`WHERE( NAME = "ANDRE LIMA" )`
  ) ;
  
  ok(
  parse(q` NAME == 1 && (C1 == 'x' && C2 == x"moh"asdasd) USER == 0`) ,
  q`WHERE( NAME = 1 AND (C1 = 'x' AND C2 = "x\"moh\"asdasd") AND USER = 0 )`
  ) ;
  
  ok(
  parse( ["bar = x && foo = ?",qw(a b c)] ) ,
  q`WHERE( ((bar = "x" AND foo = "a")) OR ((bar = "x" AND foo = "b")) OR ((bar = "x" AND foo = "c")) )`
  ) ;

  ok(
  parse( ["foo = ?",qw(a b c)] ) ,
  q`WHERE( (foo = "a") OR (foo = "b") OR (foo = "c") )`
  ) ;
  
  ok(
  parse( ["id = 1 && (box = ? || de = ?)",'gm'] ) ,
  q`WHERE( (id = 1 AND (box = "gm" OR de = "gm") ) )`
  ) ;
  
  ok(
  parse( 'id = 1 && (box = x || de = y)' ) ,
  q`WHERE( id = 1 AND (box = "x" OR de = "y")  )`
  ) ;
  
  ok(
  parse( 'foo = "x and" (id > 0 || id < 100) || user = gm' ) ,
  q`WHERE( foo = "x and" AND (id > 0 OR id < 100) OR user = "gm" )`
  ) ;

}
#########################
{
  
  eval(q`use DBD::SQLite ;`);
  
  if ( $@ ) {
    ok(1);
    print "\n** Need DBD::SQLite installed to make the tests from 9 to 19!\n" ;
    exit;
  }
  
  unlink($test_db);
  
  my $HDB = HDB->new(
  type => 'sqlite' ,
  file => $test_db ,
  warning => 0 ,
  ) ;
  
  ok($HDB) ;
  
  ##########
  # CREATE #
  ##########
  
  $HDB->drop('users') ;

  $HDB->create('users',[
  'user' => 100 ,
  'name' => 100 ,
  'age' => 'int(200)' ,
  'more' => 1024*4 ,
  ]);
    
  my @tables = $HDB->tables() ;
  
  ok( join(" ", @tables) , 'users' ) ;
  
  my @names = $HDB->names('users') ;
  
  ok( join(" ", @names) , 'user name age more id' ) ;
  
  ##########
  # INSERT #
  ##########
  
  ##$HDB->do("INSERT INTO users VALUES ('joe','joe tribianny',30,'',11)") ;

  $HDB->insert( 'users' , {
  user => 'joe1' ,
  name => 'joe tribianny1' ,
  age  => '31' ,
  } ) ;
  
  $HDB->insert( 'users' , {
  user => 'joe2' ,
  name => 'joe tribianny2' ,
  age  => '32' ,
  } ) ;
  
  $HDB->insert( 'users' , {
  user => 'joe3' ,
  name => 'joe tribianny3' ,
  age  => '33' ,
  } ) ;
  
  ##########
  # SELECT #
  ##########

  my @users = $HDB->select('users' , 'name =~ joe' , '@%' ) ;
  
  my $i ;
  foreach my $user ( @users ) {
    ++$i ;
    ok($$user{user} , 'joe' . $i) ;
    ok($$user{name} , 'joe tribianny' . $i) ;
    ok($$user{age} , 30 + $i) ;
  }
  
  ##########
  # UPDATE #
  ##########
  
  ok( $HDB->update('users' , 'name =~ joe' , { user => 'JoeT' } ) ) ;
  
  ok( !$HDB->select('users' , 'user eq joe' , '$$' ) ) ;

  my $name = $HDB->select('users' , 'user eq JoeT' , col => 'name' , '$$' ) ;
  ok( $name , 'joe tribianny1' ) ;
  
  ##########
  # DELETE #
  ##########
  
  ok( $HDB->delete('users' , 'name =~ joe' , '@%' ) ) ;
  
  @users = $HDB->select('users' , 'name =~ joe' , '@%' ) ;
  
  ok( !@users ) ;

}
#########################

print "\nThe End! By!\n" ;

1 ;


