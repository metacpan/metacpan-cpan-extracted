package Judy::1;

use strict;
use warnings;

use Judy::_obj -impl;

sub TIEHASH {
    my @self;
    
    # I wish I had := binding here.
    for ( $_[1] ) {
        for ( $_->{ptrpath} ) {
            $self[_ptrpath] = $_ if $_;
        }
        for ( $_->{ptr} ) {
            $self[_ptr]    = $_ if $_;
        }
    }

    return bless \@self, $_[0];
}

sub FETCH {
    my $ptr = $_[0]->ptr;
    return Test( $ptr, $_[1] );
}

sub STORE {
    my $ptr = my $optr = $_[0]->ptr;

    if ( $_[2] ) {
        Set( $ptr, $_[1] );
    }
    else {
        Unset( $ptr, $_[1] );
    }

    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }

    return !! $_[2];
}

sub EXISTS {
    my $ptr = $_[0]->ptr;
    return Test( $ptr, $_[1] );
}

sub DELETE {
    my $optr = my $ptr = $_[0]->ptr;

    my $oldval = Unset( $ptr, $_[1] );
    
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }
    
    return $oldval;
}

sub CLEAR {
    my $optr = my $ptr = $_[0]->ptr;
    Free( $ptr );
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }
}

sub FIRSTKEY {
    my $ptr = $_[0]->ptr;
    return First( $ptr, 0 );
}

sub NEXTKEY {
    my $ptr = $_[0]->ptr;
    return Next( $ptr, $_[1] );
}

# Not implemented.
sub SCALAR;

sub UNTIE {}

sub DESTROY {}

1;
