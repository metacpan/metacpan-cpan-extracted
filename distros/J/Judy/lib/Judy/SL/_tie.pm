package Judy::SL;

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
    my ( undef, $val ) = Get( $ptr, $_[1] );
    return $val;
}

sub STORE {
    my $ptr = my $optr = $_[0]->ptr;
    my $val = defined $_[2] ? $_[2] : 0;
    my $pval = Set( $ptr, $_[1], $val );
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }
    return $val;
}

sub EXISTS {
    my $ptr = $_[0]->ptr;
    my ( $pval ) = Get( $ptr, $_[1] );
    return !! $pval;
}

sub DELETE {
    my $optr = my $ptr = $_[0]->ptr;

    my $val;
    if ( defined wantarray ) {
        ( undef, $val ) = Get( $ptr, $_[1] );
        return if ! defined $val;
    }
    
    Delete( $ptr, $_[1] );
    if ( $optr != $ptr ) {
        $_[0]->setptr( $ptr );
    }
    
    return $val;
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
    my ( undef, undef, $key ) = First( $ptr, '' );
    return $key;
}

sub NEXTKEY {
    my $ptr = $_[0]->ptr;
    my ( undef, undef, $key ) = Next( $ptr, $_[1] );
    return $key;
}

# Not implemented.
sub SCALAR {
    my $count = 0;
    my $ptr = $_[0]->ptr;
    my ( undef, undef, $key ) = First( $ptr, '' );
    while ( defined $key ) {
        ++ $count;
        ( undef, undef, $key ) = Next( $ptr, $key );
    }

    return $count;
}

sub UNTIE {}

sub DESTROY {}

1;
