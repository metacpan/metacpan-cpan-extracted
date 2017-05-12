package
  Subst ;
 
use Filter::Util::Call ;
use Carp ;

use strict ;
use warnings ;
 
sub import
{
    croak("usage: use Subst qw(from to)")
        unless @_ == 3 ;
    my ($self, $from, $to) = @_ ;
    filter_add(
        sub 
        {
            my ($status) ;
            s/$from/$to/
                if ($status = filter_read()) > 0 ;
            $status ;
        })
}
 
1 ;
