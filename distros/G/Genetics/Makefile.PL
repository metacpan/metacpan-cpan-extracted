BEGIN {require 5.004;}
use strict;
use ExtUtils::MakeMaker qw(prompt WriteMakefile);

use vars qw($VERSION $AUTHOR $ABSTRACT %PREREQ_PM);
$VERSION = '0.03' ;
$AUTHOR = 'Steve Mathias <smathias1@qwest.net>' ;
$ABSTRACT = 'Perl modules for genetic analysis' ;
%PREREQ_PM = ('DBI' => 1.08, 
	      'DBD::mysql' => 1.2208, 
	      'XML::Writer' => 0.4) ;


my($host, $database, $user, $password, $dbh, $api, $date, $subj, $id) ;
$host = prompt("MySQL database host [localhost]: ", $host) ;
$host ||= "localhost" ;
$database = prompt("MySQL database name [test]: ", $database) ;
$database ||= "test" ;
$user = prompt("MySQL username: ", $user) ;
$password = prompt("MySQL password: ", $password) ;
# This file will be used and deleted by test.t
# I'm sure there is a better way to pass these values into the test script,
# but I haven't been able to figure it out.
open(CONST, "> .test.constants") or die "Can't write file: $!" ;
print CONST "$host,$database,$user,$password" ;
close CONST ;

WriteMakefile(
	      'NAME'	  => 'Genetics',
	      'VERSION'	  => $VERSION,
	      'AUTHOR'    => $AUTHOR,
	      'ABSTRACT'  => $ABSTRACT,
	      'PREREQ_PM' => \%PREREQ_PM,
	     ) ;
