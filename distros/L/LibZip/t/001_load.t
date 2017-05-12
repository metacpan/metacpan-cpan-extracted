#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 2 } ;

sub BEGIN {
  chdir('./t') if -d './t' ;
}

use LibZip ;
ok(1) ;
  
use strict ;
use warnings qw'all' ;

$LibZip::DEBUG = 1 ;

#########################
{

  ok( LibZip::InitLib::LIBZIP =~ /(?:^|[\\\/])lib.zip$/i ) ;
  
}
#########################

print "\nThe End! By!\n" ;

1 ;
