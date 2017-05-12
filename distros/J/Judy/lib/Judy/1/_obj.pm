package Judy::1;

use strict;
use warnings;

sub first_key { 0 }

sub get {
    my $ptr = $_[0]->ptr;
    return Judy::1::Test( $ptr, $_[1] );
}

sub set {
    my $optr = my $ptr = $_[0]->ptr;

    if ( $_[2] ) {
        Judy::1::Set( $ptr, $_[1] );
    }
    else {
        Judy::1::Unset( $ptr, $_[1] );
    }
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }

    return !! $_[2] ;
}

sub delete {
    my $optr = my $ptr = $_[0]->ptr;
    my $oldval = Judy::1::Unset( $ptr, $_[1] );
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }
    return $oldval;
}

sub free {
    my $ptr = $_[0]->ptr;
    Judy::1::Free( $ptr );
    $_[0]->setptr( $ptr );
}

sub first {
    my $ptr = $_[0]->ptr;
    return Judy::1::First( $ptr, 0 );
}

sub next {
    my $ptr = $_[0]->ptr;
    return Judy::1::Next( $ptr, $_[1] );
}

sub last {
    my $ptr = $_[0]->ptr;
    return Judy::1::Last( $ptr, 0 );
}

sub prev {
    my $ptr = $_[0]->ptr;
    return Judy::1::Prev( $ptr, $_[1] );
}

1;
