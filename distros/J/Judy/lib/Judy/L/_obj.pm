package Judy::L;

use strict;
use warnings;

sub first_key { 0 }

sub get {
    my $ptr = $_[0]->ptr;
    return Judy::L::Get( $ptr, $_[1] );
}

sub set {
    my $optr = my $ptr = $_[0]->ptr;

    my $pval = Set( $ptr, $_[1], $_[2] );
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }

    return $pval;
}

sub delete {
    my $optr = my $ptr = $_[0]->ptr;
    my $oldval = Judy::L::Delete( $ptr, $_[1] );
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }
    return $oldval;
}

sub free {
    my $ptr = $_[0]->ptr;
    Judy::L::Free( $ptr );
    $_[0]->setptr( $ptr );
}

sub first {
    my $ptr = $_[0]->ptr;
    return Judy::L::First( $ptr, 0 );
}

sub next {
    my $ptr = $_[0]->ptr;
    return Judy::L::Next( $ptr, $_[1] );
}

sub last {
    my $ptr = $_[0]->ptr;
    return Judy::L::Last( $ptr, 0 );
}

sub prev {
    my $ptr = $_[0]->ptr;
    return Judy::L::Prev( $ptr, $_[1] );
}

1;
