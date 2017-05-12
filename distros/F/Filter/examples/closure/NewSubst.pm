package
  NewSubst ;
 
use Filter::Util::Call ;
use Carp ;

use strict ;
use warnings ;
 
sub import
{
    my ($self, $start, $stop, $from, $to) = @_ ;
    my ($found) = 0 ;
    croak("usage: use Subst qw(start stop from to)")
        unless @_ == 5 ;
 
    filter_add( 
        sub 
        {
            my ($status) ;
         
            if (($status = filter_read()) > 0) {
         
                $found = 1
                    if $found == 0 and /$start/ ;
         
                if ($found) {
                    s/$from/$to/ ;
                    filter_del() if /$stop/ ;
                }
         
            }
            $status ;
        } )

}
 
1 ;
