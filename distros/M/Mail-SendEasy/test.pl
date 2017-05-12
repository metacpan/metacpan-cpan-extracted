#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 6 } ;

use Mail::SendEasy ;

use strict ;
use warnings qw'all' ;

ok(1);

my ( $host , $user , $pass , $from , $to ) ;

  if ( !$host || !$user || !$pass ) {
    print "\n----------------\n" ;
    print "SMTP SERVER for the tests: " ;
    chomp( $host = <STDIN> ) ;
    print "USERNAME: " ;
    chomp( $user = <STDIN> ) ;
    print "PASSWORD: " ;
    chomp( $pass = <STDIN> ) ;
    print "FROM: " ;
    chomp( $from = <STDIN> ) ;
    print "TO: " ;
    chomp( $to = <STDIN> ) ;
  }
  
  $to ||= $from ;
  
  print "\n----------------\n" ;
  print "SETS:\n" ;
  print "  host: $host\n" ;
  print "  user: $user\n" ;
  print "  pass: $pass\n" ;
  print "  from: $from\n" ;
  print "  to:   $to\n" ;
  print "----------------\n" ;

#########################
if ($host && $from) {

  my $mail = new Mail::SendEasy(
  smtp => $host , 
  user => $user ,
  pass => $pass ,
  ) ;
  
  ok($mail) ;
  
  my $status = $mail->send(
  from    => $from ,
  from_title => 'Perl Test' ,
  to      => $to ,
  subject => "Mail::SendEasy - Perl Test" ,
  msg     => "The Plain Msg..." ,
  html    => "<b>The HTML Msg...</b>" ,
  ) ;
  
  ok($status) ;
  
  if (! $status) { print $mail->error ;}
}
else { print "## Skiped test from 2..3 (need host && from)\n" ;}
#########################
if ( $host && $user && $pass ) {

  print "## AUTH TESTS:\n" ;

  my $smtp = Mail::SendEasy::SMTP->new($host) ;

  ok($smtp) ;
  
  ok( $smtp->auth_types ) ;
  
  if ( $smtp->auth($user , $pass) ) { ok(1) ;}
  else {
    my @response = $smtp->last_response ;
    foreach my $response_i ( @response ) {
      warn("AUTH: $$response_i[0] $$response_i[1]\n") ;
    }
  }

}
else { print "## Skiped test from 4..6 (need host && user && pass)\n" ;}
#########################

print "\nThe End! By!\n" ;

1 ;
