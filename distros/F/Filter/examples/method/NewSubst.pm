package
  NewSubst ;
 
use Filter::Util::Call ;
use Carp ;
 
use strict ;
use warnings ;

sub filter
{
    my ($self) = @_ ;
    my ($status) ;
 
    if (($status = filter_read()) > 0) {
 
        $self->{Found} = 1
            if $self->{Found} == 0 and  /$self->{Start}/ ;
 
        if ($self->{Found}) {
            s/$self->{From}/$self->{To}/ ;
            filter_del() if /$self->{Stop}/ ;
        }
 
    }
    $status ;
}
 
sub import
{
    my ($self, @args) = @_ ;
    croak("usage: use Subst qw(start stop from to)")
        unless @args == 4 ;
 
    filter_add( { Start => $args[0],
                  Stop  => $args[1],
                  From  => $args[2],
                  To    => $args[3],
                  Found => 0 }
              ) ;
}
 
1 ;

