#########################

###use Data::Dumper ; print Dumper(  ) ;

use Test;
BEGIN { plan tests => 4 } ;


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

  eval{
    require LibZipFOO ;
  };
  ok(!$@) ;
  
  my @ret = LibZipFOO::test(123 , 456);
  
  ok( $ret[0] , 'OK') ;
  ok( $ret[1] , '123 456') ;
  
}
#########################

print "\nThe End! By!\n" ;

1 ;
