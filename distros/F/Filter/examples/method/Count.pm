package
  Count;
 
use Filter::Util::Call ;
 
use strict ;
use warnings ;

sub filter
{
    my ($self) = @_ ;
    my ($status) ;
 
    if (($status = filter_read()) > 0 ) {
        s/Joe/Jim/g ;
        ++ $$self ;
    }
    elsif ($$self >= 0) { # EOF
        $_ = "print q[Made ${$self} substitutions\n] ;" ;
        $status = 1 ;
	$$self = -1 ;
    }
 
    $status ;
}
 
sub import
{
    my ($self) = @_ ;
    my ($count) = 0 ;
    filter_add(\$count) ;
}
 
1 ;

