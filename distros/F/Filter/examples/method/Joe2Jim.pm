package
  Joe2Jim ;
 
use Filter::Util::Call ;

use strict ;
use warnings ;
 
sub import
{
    my($type) = @_ ;
 
    filter_add(bless []) ;
}
 
sub filter
{
    my($self) = @_ ;
    my($status) ;
 
    s/Joe/Jim/g
        if ($status = filter_read()) > 0 ;
    $status ;
}
 
1 ;

