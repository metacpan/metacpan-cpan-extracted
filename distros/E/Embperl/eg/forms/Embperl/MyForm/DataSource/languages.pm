
package Embperl::MyForm::DataSource::languages ;

use strict ;

use base 'Embperl::Form::DataSource' ;


# ---------------------------------------------------------------------------
#
#   get_values - returns the values and options
#

sub get_values

    {
    my ($self, $req, $ctrl) = @_ ;

    my @options ;
    my @values ;
    
    if (!$ctrl -> {noblank})
        {
        push @options, '---' ;
        push @values, '' ;
        }

    push @options, 'Deutsch','English' ;
    push @values, 'de_DE','en_US' ;
    

    return (\@values, \@options) ;
    }


1 ;

__END__

