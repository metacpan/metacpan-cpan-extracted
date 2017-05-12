package Judy::_obj;

use strict;
use warnings;

# Object accessors
use constant _ptr      => 0;
use constant _ptrpath  => 1;
use constant _type     => 2;
use constant _fulltype => 3;
use constant _innerobj => 4;

use constant NULL => 0x0;

use constant _impl => [qw[ _ptr _ptrpath _type _fulltype _innerobj NULL ptr setptr ptrptr ]];
use Sub::Exporter -setup => {
    groups => {
        impl => _impl,
    },
    exports => _impl
};

# 0 for the types and 1, L, '' for the types SL and HS.
#
sub first_key;

sub DESTROY {}

sub ptrptr {
    for ( $_[0][_ptrpath] ) {
        return if ! $_;
        my $container     = $_->[0];
        my $container_obj = $container->[_innerobj];
        my $container_key = $_->[1];
        my ( $pval, $val ) = $container_obj->get( $container_key ); 
        #printf "0x%x->ptrptr(0x%x)=0x%x. *0x%4\$x = 0x%x\n",
        #    $container_obj->ptr,
        #    $container_key,
        #    $pval,
        #    $val;
        return $pval;
   }
}

sub setptr {
    for ( $_[0] ) {
        if ( $_->[_ptrpath] ) {
            my ( $pval ) = $_[0]->ptrptr;
            #printf  "*0x%x <- 0x%x\n", $pval, $_[1];
            Judy::Mem::Poke( $pval, $_[1] );
            return $_[1];
        }
        else {
            return $_->[_ptr] = $_[1];
        }
    }
}

sub ptr {
    for ( $_[0] ) {
        # Sanity check.
        #
        if ( $_->[_ptr] && $_->[_ptrpath] ) {
            my $ptrptr = $_[0]->ptrpr;
            my $a = Judy::Mem::Peek($ptrptr);
            my $b = $_->[_ptr];
            if ( $a != $b ) {
                Carp::confess( "\*$a != $b" );
            }
        }
        
        if ( $_->[_ptr] ) {
            return $_->[_ptr];
        }
        elsif ( $_->[_ptrpath] ) {
            my $ptrptr = $_[0]->ptrptr;
            return Judy::Mem::Peek( $ptrptr );
        }
        else {
            return NULL;
        }
    }
}


1;
