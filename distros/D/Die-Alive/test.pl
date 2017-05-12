#########################

use Test;
BEGIN { plan tests => 7 } ;

use Die::Alive ;

use strict ;
use warnings qw'all' ;

#########################
{

  my ( @dies , @warns ) ; 

  $SIG{__DIE__} = sub { push(@dies , @_) ;} ;
  $SIG{__WARN__} = sub { push(@warns , @_) ;} ;

  die("This die() won't exit!\n") ;
  
  ok(1);
  
  my $skeep ;
  eval {
    die("die inside eval!\n") ;
    $skeep = 1 ;
  } ;
  
  ok($@ , "die inside eval!\n");
  ok(!$skeep);
  
  ok( $#dies == 0 ) ;
  ok( $#warns == 0 ) ;
  
  ok( $dies[0] , "die inside eval!\n") ;
  ok( $warns[0] , "This die() won't exit!\n") ;

}
#########################

print "\nThe End! By!\n" ;

1 ;
