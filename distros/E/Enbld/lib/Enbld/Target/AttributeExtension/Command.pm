package Enbld::Target::AttributeExtension::Command;

use strict;
use warnings;

use parent qw/Enbld::Target::Attribute/;

our $make;

sub make_command {

    return $make if $make;

    if ( `which gmake` ) {
        return ( $make = 'gmake' );
    } elsif ( `make -v 2>&1` =~ /GNU Make/ ) {
        return ( $make = 'make' );
    } else {
        require Enbld::Error;
        die( Enbld::Error->new( 'GNU Make is NOT installed' ));
    }
}

1;
