package Enbld::Message;

use strict;
use warnings;

our $VERBOSE;

sub notify {
    my ( $pkg, $msg ) = @_;

    chomp( $msg );
    $msg .= "\n";

    require Enbld::Logger;
    Enbld::Logger->write( $msg ) if Enbld::Logger->logfile;
    
    print $msg if $VERBOSE;
}

sub alert {
    my ( $pkg, $msg ) = @_;

    chomp( $msg );
    $msg .= "\n";

    require Enbld::Logger;
    Enbld::Logger->write( $msg ) if Enbld::Logger->logfile;
    
    print STDERR $msg if $VERBOSE;
}

sub set_verbose {
    $VERBOSE++;
}

1;

