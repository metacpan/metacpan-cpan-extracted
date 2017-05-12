package Judy;

use strict;
use warnings;

use Judy::_obj -impl;

use constant TYPE => 1;
use constant ARGS => 2;

sub TIEHASH {
    # Allow spaces and such in the spec but remove them prior to use.
    # Normal specs look like: 'Judy::1' or 'Judy::L -> Judy::1'
    #
    my $fulltype = $_[TYPE];
    $fulltype =~ s/[(\s)]+//g;

    # Detect whether this is a simple object or not.
    #
    if ( -1 == index $fulltype, '->' ) {

        # Allow '1' instead of 'Judy::1'
        #
        if ( -1 == index $fulltype, ':' ) {
            $fulltype = "Judy::$fulltype";
        }

        # Return a non-Judy object. No need to get extra re-dispatching
        #
        if ( $Devel::Trace::TRACE ) {
            printf "%s:%d %s->TIEHASH( $_[TYPE], $_[ARGS] )\n", __FILE__, __LINE__, $_[0], $_[TYPE], $_[ARGS];
        }
        return $fulltype->TIEHASH( $_[ARGS] ? $_[ARGS] : () );
    }
    else {
        # Tie a simple, non-Judy array internally.
        #
        my ( $type ) = $fulltype =~ /^([\w:']+)/
            or die;

        # Allow '1' instead of 'Judy::1'
        #
        if ( -1 == index $type, ':' ) {
            $type = "Judy::$type";
        }

        my @self;
        $self[_innerobj] = $type->TIEHASH( $_[ARGS] ? $_[ARGS] : () );

        # Store the complete type: Judy::SL->Judy::SL->...
        #
        $self[_fulltype]  = $fulltype;
        $self[_type]      = $type;

        return bless \ @self, 'Judy';
    }
}

use constant SELF => 0;
use constant KEY  => 1;
use constant VALUE => 2;

sub FETCH {
    for ( $_[SELF][_innerobj] ) {
        
        # Fetch the next hash.
        #
        my ( $pval, $val) = $_->get( $_[KEY] );
        
        # Autovivify the current hash. This is more eager than normal perl.
        #
        if ( ! $pval ) {
            my $optr = $_->ptr;
            $pval = $_->set( $_[KEY], NULL );
            
            my $ptr = $_->ptr;
            
            if ( $optr != $ptr ) {
                $_->setptr( $ptr );
            }
        }
        
        my $innertype = $_[SELF][_fulltype];
        $innertype =~ s/^[\w:']+->//;
        
        # printf "%s:%d innertype=%s\n", __FILE__, __LINE__, $innertype;

        # Return the desired thing. Let Judy decide whether it wants to delegate or not.
        #
        tie my(%h), Judy => $innertype, { ptrpath => [ $_[SELF], $_[KEY]] };
        return \ %h;
    }
}

sub STORE {
    for ( $_[SELF][_innerobj] ) {

        # Fetch the current hash to detect orphans.
        #
        my ( $pval, $val ) = $_->get( $_[KEY] );
        if ( $val ) {
            warn( sprintf "Orphaning %s(0x%x)", $_[SELF][_type], $val );
        }
        
        # Store the new pointer.
        #
        my $storeobj = tied %{ $_[VALUE] };
        my $storeptr = $storeobj->ptr;
        if ( $pval ) {
            Judy::Mem::Poke( $pval, $storeptr );
        }
        else {
            my $optr = $_->ptr;
            $pval = $_->set( $_[KEY], $storeptr );
            my $ptr = $_->ptr;
            if ( $ptr != $optr ) {
                $_->setptr($ptr);
            }
        }
        
        # Return the stored thingy.
        #
        if ( defined wantarray ) {
            tie my(%h), Judy => $_[SELF][_type], { ptrpath => [ $_[SELF], $_[KEY]] };
            return \%h;
        }
    }
}

sub EXISTS {
    my ( $pval ) = $_[SELF][_innerobj]->get( $_[KEY] );
    return defined $pval;
}

sub FIRSTKEY {
    my ( undef, undef, $key ) = $_[SELF][_innerobj]->first;
    return $key;
}

sub NEXTKEY {
    my ( undef, undef, $key ) = $_[SELF][_innerobj]->next( $_[KEY] );
    return $key;
}

sub DELETE {
    my ( undef, $val ) = $_[SELF][_innerobj]->delete( $_[KEY] );
    return defined $val ? $val : ();
}

sub CLEAR {
    for ( $_[SELF][_innerobj] ) {
        $_->free;
        my $ptr = $_->ptr;
        $_->setptr( $ptr );

        return;
    }
}

sub SCALAR {
    Carp::confess('not implemented');
}

sub UNTIE {
}

sub DESTROY {
}

1;
