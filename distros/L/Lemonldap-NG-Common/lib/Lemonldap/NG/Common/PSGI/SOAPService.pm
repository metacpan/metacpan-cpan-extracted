## @file
# SOAP wrapper used to restrict exported functions

## @class
# SOAP wrapper used to restrict exported functions
package Lemonldap::NG::Common::PSGI::SOAPService;

use strict;

require SOAP::Lite;

our $VERSION = '2.0.10';

## @cmethod Lemonldap::NG::Common::PSGI::SOAPService new(object obj,string @func)
# Constructor
# @param $obj object which will be called for SOAP authorized methods
# @param @func authorized methods
# @return Lemonldap::NG::Common::PSGI::SOAPService object
sub new {
    my ( $class, $obj, $req, @func ) = @_;
    s/.*::// foreach (@func);
    return bless { obj => $obj, func => \@func, req => $req }, $class;
}

## @method data AUTOLOAD()
# Call the wanted function with the object given to the constructor.
# AUTOLOAD() is a magic method called by Perl interpreter fon non existent
# functions. Here, we use it to call the wanted function (given by $AUTOLOAD)
# if it is authorized
# @return data provided by the exported function
sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD =~ s/.*:://;
    if ( grep { $_ eq $AUTOLOAD } @{ $self->{func} } ) {
        my $tmp = $self->{obj}->$AUTOLOAD( $self->{req}, @_ );
        unless ( ref($tmp) and ref($tmp) =~ /^SOAP/ ) {
            $tmp = SOAP::Data->name( result => $tmp );
        }
        return $tmp;
    }
    elsif ( $AUTOLOAD ne 'DESTROY' ) {
        die "$AUTOLOAD is not an authorized function";
    }
    1;
}

1;
