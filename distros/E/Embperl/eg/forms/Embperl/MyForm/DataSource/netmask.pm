
package Embperl::MyForm::DataSource::netmask ;

use strict ;

use base 'Embperl::Form::DataSource' ;


# ---------------------------------------------------------------------------
#
#   get_values - returns the values and options
#

sub get_values

    {
    my ($self, $req, $ctrl) = @_ ;

    my $i = 33 ;
    my @netmaskvalues;
 
    my @netmaskoptions = map { $i-- ; push @netmaskvalues, $i ; "/$i ($_)" } (
    '255.255.255.255',
    '255.255.255.254',
    '255.255.255.252',
    '255.255.255.248',
    '255.255.255.240',
    '255.255.255.224',
    '255.255.255.192',
    '255.255.255.128',
    '255.255.255.0',
    '255.255.254.0',
    '255.255.252.0',
    '255.255.248.0',
    '255.255.240.0',
    '255.255.224.0',
    '255.255.192.0',
    '255.255.128.0',
    '255.255.0.0',
    '255.254.0.0',
    '255.252.0.0',
    '255.248.0.0',
    '255.240.0.0',
    '255.224.0.0',
    '255.192.0.0',
    '255.128.0.0',
    '255.0.0.0',
    ) ;

    return (\@netmaskvalues, \@netmaskoptions) ;
    }


1 ;

__END__

