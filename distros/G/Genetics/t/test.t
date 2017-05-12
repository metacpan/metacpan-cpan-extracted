use strict;
use Test ;

BEGIN { 
  $| = 1 ; 
  plan tests => 4 ;
}

sub test ($$;$) {
  my($num, $true, $msg) = @_ ; 
  print($true ? "ok $num\n" : "not ok $num $msg\n") ; 
} 


test 1, require DBI, "DBI is not installed." ;

test 2, grep /^mysql$/, DBI->available_drivers(), "DBD::mysql is not installed" ;

my($const, $host, $database, $user, $password, $dbh, $api, $date, $subj, $id) ;
open(CONST, ".test.constants") or die "Can't open file: $!" ;
$const = <CONST> ;
($host, $database, $user, $password) = split ",", $const ;
close CONST ;
unlink ".test.constants" ;
#  print "MySQL database host [localhost]: " ;
#  chop($host = <>) ;
#  $host ||= "localhost" ;
#  print "MySQL database name [test]: " ;
#  chop($database = <>) ;
#  $database ||= "test" ;
#  print "MySQL username: " ;
#  chop($user = <>) ;
#  print "MySQL password: " ;
#  chop($password = <>) ;

test 3, $dbh = DBI->connect("DBI:mysql:database=$database;host=$host", 
		    $user, $password), "Unable to connect to MySQL database" ;

test 4, require Genetics::API ;

#  test 5, $api = new Genetics::API(DSN => {driver   => "mysql", 
#  					 host     => $host, 
#  					 database => $database}, 
#  				 user     => $user, 
#  				 password => $password, 
#  				), "Can't instantiate Genetics::API object." ;

#  use Genetics::Util qw(now) ;
#  test 6, $date = now(format => 'mysqldate'), "No Genetics::Util." ;

#  test 7, $subj = new Genetics::Subject(name => 'Test Subject 1',
#  				      importID => 't1',
#  				      dateCreated => $date,
#  				      Keywords => [ {name => "Test Data", 
#  						     dataType => "Boolean", 
#  						     value => 1}
#  						  ], 
#  				      gender => "Female",
#  				      dateOfBirth => "1937-08-18", 
#  				      dateOfDeath => "1997-02-15",
#  				      Organism => {genusSpecies => "Homo sapiens"},
#  				     ), "Can't instantiate Subject object." ;

#  test 8, $id = $api->insertSubject($subj), "Can't save Subject." ;

#  test 9, $subj = $api->getSubject($id), "Can't retrieve Subject." ;

#  $subj->name("New test name") ;
#  $subj->gender("Male") ;
#  test 10, $api->updateSubject($subj), "Can't update Subject." ;

#  test 11, $api->deleteSubject($id), "Can't delete Subject." ;
