/*
#
# This file is part of Language::Befunge::Vector::XS.
# Copyright (c) 2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#
*/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#include "ppport.h"


/* used for constructor new() */
typedef int intArray;
void* intArrayPtr(int num) {
    SV* mortal;
    mortal = sv_2mortal( NEWSV(0, num * sizeof(intArray)) );
    return SvPVX(mortal);
}

AV *_rasterize(AV *vec_array, AV *min_array, AV *max_array) {
    IV i, inc = 1, nd = av_len(vec_array);
    AV *rv = newAV();
    for (i = 0; i <= av_len(vec_array); i++) {
        IV thisval, minval, maxval;
        thisval = SvIV(*av_fetch(vec_array, i, 0));
        minval  = SvIV(*av_fetch(min_array, i, 0));
        maxval  = SvIV(*av_fetch(max_array, i, 0));
        if(inc) {
            if(thisval < maxval) {
                inc = 0;
                thisval++;
            } else {
                if(i == nd) {
                    SvREFCNT_dec(rv);
                    return NULL;
                }
                thisval = minval;
            }
        }
        av_push(rv, newSViv(thisval));
    }
    return rv;
}


MODULE = Language::Befunge::Vector::XS		PACKAGE = Language::Befunge::Vector::XS


#-- CONSTRUCTORS

#
# my $vec = LB::Vector->new( $x [, $y, ...] );
#
# Create a new vector. The arguments are the actual vector data; one
# integer per dimension.
#
SV *
new( class, array, ... )
        char*      class;
        intArray*  array
    INIT:
            IV     i;
            SV*    self;
            SV*    val;
            AV*    my_array;
            HV*    stash;
    CODE:
        /* sanity checks */
        if ( ix_array < 0 )
        	croak("Usage: %s->new($x,...)", class);

        /* create the object and populate it */
        my_array = newAV();
        for ( i=0; i<ix_array; i++ ) {
            val = newSViv( array[i] );
            av_push(my_array, val);
        }

        /* Return a blessed reference to the AV */
        self  = newRV_noinc( (SV*)my_array );
        stash = gv_stashpv( class, TRUE );
        sv_bless( (SV*)self, stash );
        RETVAL = self;
    OUTPUT:
        RETVAL


#
# my $vec = Language::Befunge::Vector::XS->new_zeroes( $dims );
#
# Create a new vector of dimension $dims, set to the origin (all
# zeroes). LBVXS->new_zeroes(2) is exactly equivalent to LBVXS->new(0, 0).
#
SV *
new_zeroes( class, dim )
        char*  class;
        IV     dim;
    INIT:
        IV     i;
        SV*    self;
        SV*    zero;
        AV*    my_array;
        HV*    stash;
    CODE:
        /* sanity checks */
        if ( dim < 1 )
        	croak("Usage: %s->new_zeroes($dims)", class);

        /* create the object and populate it */
        my_array = newAV();
        for ( i=0; i<dim; i++ ) {
            zero = newSViv(0);
            av_push(my_array, zero);
        }

        /* return a blessed reference to the AV */
        self  = newRV_noinc( (SV*)my_array );
        stash = gv_stashpv( class, TRUE );
        sv_bless( (SV*)self, stash );
        RETVAL = self;
    OUTPUT:
        RETVAL


#
# my $vec = $v->copy;
#
# Return a new LBVXS object, which has the same dimensions and
# coordinates as $v.
#
SV*
copy( vec, ... )
        SV*  vec;
    INIT:
        IV   i;
        SV*  val;
        SV*  self;
        AV*  my_array;
        AV*  vec_array;
        HV*  stash;
    CODE:
        /* fetch the underlying array of the object */
        vec_array = (AV*)SvRV(vec);

        /* create the object and populate it */
        my_array = newAV();
        for ( i=0; i<=av_len(vec_array); i++ ) {
            val = newSViv( SvIV(*av_fetch(vec_array, i, 0)) );
            av_push(my_array, val);
        }

        /* return a blessed reference to the AV */
        self  = newRV_noinc( (SV*)my_array );
        stash = SvSTASH( (SV*)vec_array );
        sv_bless( (SV*)self, stash );
        RETVAL = self;
    OUTPUT:
        RETVAL


#-- PUBLIC METHODS

#- accessors

#
# my $dims = $vec->get_dims;
#
# Return the number of dimensions, an integer.
#
IV
get_dims( self )
        SV*  self;
    PREINIT:
        AV*  my_array;
    CODE:
        /* fetch the underlying array of the object */
        my_array = (AV*)SvRV(self);

        RETVAL = av_len(my_array) + 1;
    OUTPUT:
        RETVAL


#
# my $val = $vec->get_component($dim);
#
# Return the value for dimension $dim.
#
IV
get_component( self, dim )
        SV*  self;
        IV   dim;
    PREINIT:
        AV*  my_array;
    CODE:
        /* fetch the underlying array of the object */
        my_array = (AV*)SvRV(self);

        /* sanity checks */
        if ( dim < 0 || dim > av_len(my_array) )
            croak( "No such dimension!" );

        RETVAL = SvIV( *av_fetch(my_array, dim, 0) );
    OUTPUT:
        RETVAL


#
# my @vals = $vec->get_all_components;
#
# Get the values for all dimensions, in order from 0..N.
#
void
get_all_components( self )
        SV*  self;
    PREINIT:
        IV   dim, i, val;
        AV*  my_array;
    PPCODE:
        /* fetch the underlying array of the object */
        my_array = (AV*)SvRV(self);
        dim = av_len(my_array);

        /* extend the return stack and populate it */
        EXTEND(SP,dim+1);
        for ( i=0; i<=dim; i++ ) {
            val = SvIV( *av_fetch(my_array, i, 0) );
            PUSHs( sv_2mortal( newSViv(val) ) );
        }


#- mutators

#
# $vec->clear;
#
# Set the vector back to the origin, all 0's.
#
void
clear( self )
        SV*  self;
    INIT:
        IV   dim, i;
        SV*  zero;
        AV*  my_array;
    PPCODE:
        /* fetch the underlying array of the object */
        my_array = (AV*)SvRV(self);
        dim = av_len(my_array);

        /* clear each slot */
        for ( i=0; i<=dim; i++ ) {
            zero = newSViv(0);
            av_store(my_array, i, zero);
        }


#
# my $val = $vec->set_component( $dim, $value );
#
# Set the value for dimension $dim to $value.
#
void
set_component( self, dim, value )
        SV*  self;
        IV   dim;
        IV   value;
    INIT:
        AV*  my_array;
    CODE:
        /* fetch the underlying array of the object */
        my_array = (AV*)SvRV(self);

        /* sanity checks */
        if ( dim < 0 || dim > av_len(my_array) )
            croak( "No such dimension!" );

        /* storing new value */
        av_store(my_array, dim, newSViv(value));

 
#- other methods

#
# my $is_within = $vec->bounds_check($begin, $end);
#
# Check whether $vec is within the box defined by $begin and $end.
# Return 1 if vector is contained within the box, and 0 otherwise.
#
IV
bounds_check( self, v1, v2 )
        SV*  self;
        SV*  v1;
        SV*  v2;
    INIT:
        IV   i, mydim, dimv1, dimv2, myval, val1, val2;
        AV*  my_array;
        AV*  v1_array;
        AV*  v2_array;
    CODE:
        /* fetch the underlying array of the object */
        my_array = (AV*)SvRV(self);
        v1_array = (AV*)SvRV(v1);
        v2_array = (AV*)SvRV(v2);
        mydim = av_len(my_array);
        dimv1 = av_len(v1_array);
        dimv2 = av_len(v2_array);

        /* sanity checks */
        if ( mydim != dimv1 || mydim != dimv2 )
            croak("uneven dimensions in bounds check!");

        /* compare the arrays */
        RETVAL = 1;
        for ( i=0 ; i<=dimv1; i++ ) {
            myval = SvIV( *av_fetch(my_array, i, 0) );
            val1  = SvIV( *av_fetch(v1_array, i, 0) );
            val2  = SvIV( *av_fetch(v2_array, i, 0) );
            if ( myval < val1 || myval > val2 ) {
                RETVAL = 0;
                break;
            }
        }
    OUTPUT:
        RETVAL


#
# for(my $v = $min->copy; defined $v; $v = $v->rasterize($min, $max))
#
# Return the next vector in raster order, or undef if the hypercube space
# has been fully covered.  To enumerate the entire storage area, the caller
# should call rasterize on the storage area's "min" value the first time,
# and keep looping while the return value is defined.  To enumerate a
# smaller rectangle, the caller should pass in the min and max vectors
# describing the rectangle, and keep looping while the return value is
# defined.
#
SV*
rasterize( self, minv, maxv )
        SV* self;
        SV* minv;
        SV* maxv;
    INIT:
        SV*  new;
        AV*  my_array;
        AV*  vec_array, *min_array, *max_array;
        HV*  stash;
    CODE:
        /* fetch the underlying array of the object */
        vec_array = (AV*)SvRV(self);
        min_array = (AV*)SvRV(minv);
        max_array = (AV*)SvRV(maxv);

        /* create the object and populate it */
        my_array = _rasterize(vec_array, min_array, max_array);
        if(!my_array) {
            XSRETURN_UNDEF;
        }

        /* return a blessed reference to the AV */
        RETVAL = newRV_noinc( (SV*)my_array );
        stash  = SvSTASH( (SV*)vec_array );
        sv_bless( (SV*)RETVAL, stash );
    OUTPUT:
        RETVAL



# -- PRIVATE METHODS

#- math ops

#
# my $vec = $v1->_add($v2);
# my $vec = $v1 + $v2;
#
# Return a new LBVXS object, which is the result of $v1 plus $v2.
#
SV*
_add( v1, v2, variant )
        SV*  v1;
        SV*  v2;
        SV*  variant;
    INIT:
        IV   dimv1, dimv2, i, val1, val2;
        SV*  self;
        AV*  my_array;
        AV*  v1_array;
        AV*  v2_array;
        HV*  stash;
    CODE:
        /* fetch the underlying array of the object */
        v1_array = (AV*)SvRV(v1);
        v2_array = (AV*)SvRV(v2);
        dimv1 = av_len(v1_array);
        dimv2 = av_len(v2_array);

        /* sanity checks */
        if ( dimv1 != dimv2 )
            croak("uneven dimensions in vector addition!");

        /* create the new array and populate it */
        my_array = newAV();
        for ( i=0 ; i<=dimv1; i++ ) {
            val1 = SvIV( *av_fetch(v1_array, i, 0) );
            val2 = SvIV( *av_fetch(v2_array, i, 0) );
            av_push( my_array, newSViv(val1+val2) );
	    }

        /* return a blessed reference to the AV */
        self  = newRV_noinc( (SV*)my_array );
        stash = SvSTASH( (SV*)v1_array );
        sv_bless( (SV*)self, stash );
        RETVAL = self;
    OUTPUT:
        RETVAL


#
# my $vec = $v1->_substract($v2);
# my $vec = $v1 - $v2;
#
# Return a new LBVXS object, which is the result of $v1 minus $v2.
#
SV*
_substract( v1, v2, variant )
        SV*  v1;
        SV*  v2;
        SV*  variant;
    INIT:
        IV   dimv1, dimv2, i, val1, val2;
        SV*  self;
        AV*  my_array;
        AV*  v1_array;
        AV*  v2_array;
        HV*  stash;
    CODE:
        /* fetch the underlying array of the object */
        v1_array = (AV*)SvRV(v1);
        v2_array = (AV*)SvRV(v2);
        dimv1 = av_len(v1_array);
        dimv2 = av_len(v2_array);

        /* sanity checks */
        if ( dimv1 != dimv2 )
            croak("uneven dimensions in vector addition!");

        /* create the new array and populate it */
        my_array = newAV();
        for ( i=0 ; i<=dimv1; i++ ) {
            val1 = SvIV( *av_fetch(v1_array, i, 0) );
            val2 = SvIV( *av_fetch(v2_array, i, 0) );
            av_push( my_array, newSViv(val1-val2) );
	    }

        /* return a blessed reference to the AV */
        self  = newRV_noinc( (SV*)my_array );
        stash = SvSTASH( (SV*)v1_array );
        sv_bless( (SV*)self, stash );
        RETVAL = self;
    OUTPUT:
        RETVAL


#
# my $vec = $v1->_invert;
# my $vec = -$v1;
#
# Subtract $v1 from the origin. Effectively, gives the inverse of the
# original vector. The new vector is the same distance from the origin,
# in the opposite direction.
#
SV*
_invert( v1, v2, variant )
        SV*  v1;
        SV*  v2;
        SV*  variant;
    INIT:
        IV   dim, i, val;
        SV*  self;
        AV*  my_array;
        AV*  v1_array;
        HV*  stash;
    CODE:
        /* fetch the underlying array of the object */
        v1_array = (AV*)SvRV(v1);
        dim = av_len(v1_array);

        /* create the new array and populate it */
        my_array = newAV();
        for ( i=0 ; i<=dim; i++ ) {
            val = SvIV( *av_fetch(v1_array, i, 0) );
            av_push( my_array, newSViv(-val) );
	    }

        /* return a blessed reference to the AV */
        self  = newRV_noinc( (SV*)my_array );
        stash = SvSTASH( (SV*)v1_array );
        sv_bless( (SV*)self, stash );
        RETVAL = self;
    OUTPUT:
        RETVAL



#- inplace math ops

#
# $v1->_add_inplace($v2);
# $v1 += $v2;
#
# Adds $v2 to $v1, and stores the result back into $v1.
#
SV*
_add_inplace( v1, v2, variant )
        SV*  v1;
        SV*  v2;
        SV*  variant;
    INIT:
        IV   dimv1, dimv2, i, val1, val2;
        AV*  v1_array;
        AV*  v2_array;
    CODE:
        /* fetch the underlying array of the object */
        v1_array = (AV*)SvRV(v1);
        v2_array = (AV*)SvRV(v2);
        dimv1 = av_len(v1_array);
        dimv2 = av_len(v2_array);

        /* sanity checks */
        if ( dimv1 != dimv2 )
            croak("uneven dimensions in vector addition!");

        /* update the array slots */
        for ( i=0 ; i<=dimv1; i++ ) {
            val1 = SvIV( *av_fetch(v1_array, i, 0) );
            val2 = SvIV( *av_fetch(v2_array, i, 0) );
            av_store( v1_array, i, newSViv(val1+val2) );
	    }
    OUTPUT:
        v1


#
# $v1->_substract_inplace($v2);
# $v1 -= $v2;
#
# Substract $v2 to $v1, and stores the result back into $v1.
#
SV*
_substract_inplace( v1, v2, variant )
        SV*  v1;
        SV*  v2;
        SV*  variant;
    INIT:
        IV   dimv1, dimv2, i, val1, val2;
        AV*  v1_array;
        AV*  v2_array;
    CODE:
        /* fetch the underlying array of the object */
        v1_array = (AV*)SvRV(v1);
        v2_array = (AV*)SvRV(v2);
        dimv1 = av_len(v1_array);
        dimv2 = av_len(v2_array);

        /* sanity checks */
        if ( dimv1 != dimv2 )
            croak("uneven dimensions in vector addition!");

        /* update the array slots */
        for ( i=0 ; i<=dimv1; i++ ) {
            val1 = SvIV( *av_fetch(v1_array, i, 0) );
            val2 = SvIV( *av_fetch(v2_array, i, 0) );
            av_store( v1_array, i, newSViv(val1-val2) );
	    }
    OUTPUT:
        v1


#- comparison

#
# my $bool = $v1->_compare($v2);
# my $bool = $v1 <=> $v2;
#
# Check whether the vectors both point at the same spot. Return 0 if they
# do, 1 if they don't.
#
IV
_compare( v1, v2, variant )
        SV*  v1;
        SV*  v2;
        SV*  variant;

    INIT:
        IV   dimv1, dimv2, i, val1, val2;
        AV*  v1_array;
        AV*  v2_array;
    CODE:
        /* fetch the underlying array of the object */
        v1_array = (AV*)SvRV(v1);
        v2_array = (AV*)SvRV(v2);
        dimv1 = av_len(v1_array);
        dimv2 = av_len(v2_array);

        /* sanity checks */
        if ( dimv1 != dimv2 )
            croak("uneven dimensions in bounds check!");

        /* compare the arrays */
        RETVAL = 0;
        for ( i=0 ; i<=dimv1; i++ ) {
            val1 = SvIV( *av_fetch(v1_array, i, 0) );
            val2 = SvIV( *av_fetch(v2_array, i, 0) );
            if ( val1 != val2 ) {
                RETVAL = 1;
                break;
            }
        }
    OUTPUT:
        RETVAL


# private

# my $ptr = $LBV->_xs_rasterize_ptr();
#
# Get a pointer to the C "rasterize" function, so that other XS modules can
# call it directly for speed.

SV*
_xs_rasterize_ptr()
    INIT:
        void *ptr = _rasterize;
        SV *rv;
    CODE:
        rv = newSVpvn((const char *)(&ptr), sizeof(ptr));
        RETVAL = rv;
    OUTPUT:
        RETVAL
