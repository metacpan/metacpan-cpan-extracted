package Judy::SL;

use strict;
use warnings;

sub first_key { 0 }

sub get {
    my $ptr = $_[0]->ptr;
    return Judy::SL::Get( $ptr, $_[1] );
}

sub set {
    my $optr = my $ptr = $_[0]->ptr;

    my $pval = Judy::SL::Set( $ptr, $_[1], $_[2] );
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }

    return $pval;
}

sub delete {
    my $optr = my $ptr = $_[0]->ptr;

    my $pval;
    if ( defined wantarray ) {
        ( $pval ) = Judy::SL::Get( $ptr, $_[1] );
    }

    Judy::SL::Delete( $ptr, $_[1] );
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }
    return $pval;
}

sub free {
    my $ptr = $_[0]->ptr;
    Judy::SL::Free( $ptr );
    $_[0]->setptr( $ptr );
}

sub first {
    my $ptr = $_[0]->ptr;
    return Judy::SL::First( $ptr, '' );
}

sub next {
    my $ptr = $_[0]->ptr;
    return Judy::SL::Next( $ptr, $_[1] );
}

sub last {
    my $ptr = $_[0]->ptr;
    return Judy::SL::Last( $ptr, '' );
}

sub prev {
    my $ptr = $_[0]->ptr;
    return Judy::SL::Prev( $ptr, $_[1] );
}

1;
