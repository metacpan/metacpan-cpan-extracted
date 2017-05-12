package
  Subst ;
 
use Filter::Util::Call ;
use Carp ;

use strict ;
use warnings ;
 
sub filter
{
    my ($self) = @_ ;
    my ($status) ;
    my ($from) = $self->[0] ;
    my ($to) = $self->[1] ;
 
    s/$from/$to/
        if ($status = filter_read()) > 0 ;
    $status ;
}
 
sub import
{
    my ($self, @args) = @_ ;
    croak("usage: use Subst qw(from to)")
        unless @args == 2 ;
    filter_add([ @args ]) ;
}
 
1 ;

