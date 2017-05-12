/*
#
# This file is part of Language::Befunge::Storage::Generic::Vec::XS.
# Copyright (c) 2008 Mark Glines, all rights reserved.
#
# This program is licensed under the terms of the Artistic License v2.0.
# See the "LICENSE" file for details.
#
#
*/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_newRV_noinc
#include "ppport.h"

//#define DEBUG
#ifdef DEBUG
static inline void dump_Avec(int nd, AV *v) {
    int i;
    fprintf(stderr, "(");
    for(i = 0; i < nd; i++) {
        SV **thisv = av_fetch(v,   i, 0);
        if(i)
            fprintf(stderr, ",");
        if(thisv)
            fprintf(stderr, "%i", SvIV(*thisv));
        else
            fprintf(stderr, "undef");
    }
    fprintf(stderr, ")");
}
#define debug(a...) fprintf(stderr, a)
#else /* !DEBUG */
#define debug(a...)
#endif /* DEBUG */

static inline int _Aoffset(int nd, AV *v, AV *min, AV *max) {
    int i, rv = 0, lastsize = 1;
    for(i = nd - 1; i >= 0; i--) {
        IV thisv, thismin, thismax, thissize, thispos;
        SV **sthisv, **sthismin, **sthismax;
        sthisv   = av_fetch(v,   i, 0);
        sthismin = av_fetch(min, i, 0);
        sthismax = av_fetch(max, i, 0);
        thisv   = SvIV(*sthisv);
        thismin = SvIV(*sthismin);
        thismax = SvIV(*sthismax);
        thissize = thismax + 1 - thismin;
        thispos = thisv - thismin;
        rv *= thissize;
        rv += thispos;
        lastsize *= thissize;
    }
    if(rv < 0) {
#ifdef DEBUG
        debug("_Aoffset: min=");
        dump_Avec(nd, min);
        debug(" max=");
        dump_Avec(nd, max);
        debug(" v=");
        dump_Avec(nd, v);
        debug("\n");
#endif /* DEBUG */
        croak("rv < 0!");
    }
    return rv;
}


static inline int _offset(int nd, SV *sv, SV *smin, SV *smax) {
    AV *v, *min, *max;
    int i, rv = 0, lastsize = 1;
    v   = (AV*)SvRV(sv);
    min = (AV*)SvRV(smin);
    max = (AV*)SvRV(smax);
    return _Aoffset(nd, v, min, max);
}


static AV * (*call_rasterize_xs)(AV*, AV*, AV*) = NULL;
static int _xs_rasterize_tried_before = 0;

static inline void figure_out_rasterize_pointer() {
    dSP;
    SV *val;
    int count;
    char *ptr;

    if(_xs_rasterize_tried_before)
        return;
    _xs_rasterize_tried_before = 1;

    PUSHMARK(SP);
    PUTBACK;
    count = call_pv("Language::Befunge::Vector::_xs_rasterize_ptr", G_SCALAR);
    SPAGAIN;
    if(count != 1)
        goto end;
    val = POPs;
    if(!SvOK(val))
        goto end;
    ptr = SvPV_nolen(val);
    memcpy(&call_rasterize_xs, ptr, sizeof(call_rasterize_xs));
end:
    PUTBACK;
}


static inline SV *call_rasterize_perl(SV *vec, SV *min, SV *max) {
    dSP;
    int count;
    SV *rv;
    PUSHMARK(SP);
    XPUSHs(vec);
    XPUSHs(min);
    XPUSHs(max);
    PUTBACK;
    count = call_method("rasterize", G_SCALAR);
    SPAGAIN;
    if(count != 1)
        croak("rasterize returned %i values, expected exactly 1");
    rv = POPs;
    PUTBACK;
    SvREFCNT_inc(rv);
    return rv;
}


static inline void do_rasterize(SV **svec, SV *smin, SV *smax, AV **avec, AV *amin, AV *amax) {
    if(call_rasterize_xs) {
        AV *rv = call_rasterize_xs(*avec, amin, amax);
        *avec = (AV*)sv_2mortal((SV*)rv);
        if(!rv) {
            *svec = NULL;
        }
    } else {
        SV *rv = call_rasterize_perl(*svec, smin, smax);
        *svec = sv_2mortal(rv);
        sv_2mortal((SV*)*avec);
        if(SvROK(rv))
            *avec = (AV*)SvRV(rv);
        else
            *avec = NULL;
    }
}


MODULE = Language::Befunge::Storage::Generic::Vec::XS  PACKAGE = Language::Befunge::Storage::Generic::Vec::XS
PROTOTYPES: ENABLE


#
# my $value = $s->get_value($v);
#
# Return the data stored at the specified vector.
#
SV*
_get_value( self, v, torus, min, max, snd )
        SV*  self;
        SV*  v;
        SV*  torus;
        SV*  min;
        SV*  max;
        SV*  snd;
    INIT:
        int offset, nd;
        STRLEN size;
        IV *ivptr;
    CODE:
        ivptr = (IV*)SvPV(torus, size);
        nd = SvIV(snd);

        offset = _offset(nd, v, min, max);
        if(size < ((offset+1) * sizeof(IV)))
            croak("invalid offset %i (buffer is %i bytes)",offset,size);
        RETVAL = newSViv(ivptr[offset]);
    OUTPUT:
        RETVAL


#
# $s->set_value($v, $value);
#
# Write the value to the specified location.
#
void
_set_value( self, v, torus, min, max, snd, value )
        SV*  self;
        SV*  v;
        SV*  torus;
        SV*  min;
        SV*  max;
        SV*  snd;
        SV*  value;
    INIT:
        int offset, nd;
        STRLEN size;
        IV *ivptr;
    CODE:
        ivptr = (IV*)SvPV(torus, size);
        nd = SvIV(snd);

        offset = _offset(nd, v, min, max);
        if(size < ((offset+1) * sizeof(IV)))
            croak("invalid offset %i (buffer is %i bytes)",offset,size);
        ivptr[offset] = SvIV(value);


SV*
__offset( self, snd, v, min, max )
        SV *self;
        SV *snd;
        SV *v;
        SV *min;
        SV *max;
    INIT:
        int nd;
        SV **value;
        HV *selfhash;
    CODE:

        nd = SvIV(snd);

        RETVAL = newSViv(_offset(nd, v, min, max));
    OUTPUT:
        RETVAL


SV*
_expand( self, snd, point, min, max, old_min, old_max, storus )
        SV *self;
        SV *snd;
        SV *point;
        SV *min;
        SV *max;
        SV *old_min;
        SV *old_max;
        SV *storus;
    INIT:
        AV *apoint, *amin, *amax, *aoldmin, *aoldmax;
        int offset, nd, i, resize_needed = 0;
        STRLEN oldsize, newsize;
        IV *oldivptr, *newivptr, filler = 32;
        SV *snewtorus;
        void *newtorusbuf;
    CODE:
        ENTER;
        SAVETMPS;
        // setup local vars
        figure_out_rasterize_pointer();
        oldivptr = (IV*)SvPV(storus, oldsize);
        nd = SvIV(snd);
        aoldmin = (AV*)SvRV(old_min);
        aoldmax = (AV*)SvRV(old_max);
        apoint  = (AV*)SvRV(point);
        amin    = (AV*)SvRV(min);
        amax    = (AV*)SvRV(max);
        // figure out the min/max and buffer size of the new torus
        newsize = 1;
        for(i = 0; i < nd; i++) {
            int length;
            SV **spoint, **smin, **smax;
            spoint = av_fetch(apoint, i, 0);
            smin   = av_fetch(amin  , i, 0);
            smax   = av_fetch(amax  , i, 0);
            if(SvIV(*spoint) < SvIV(*smin)) {
                av_store(amin, i, newSViv(SvIV(*spoint)));
                resize_needed++;
            }
            if(SvIV(*spoint) > SvIV(*smax)) {
                av_store(amax, i, newSViv(SvIV(*spoint)));
                resize_needed++;
            }
            length = SvIV(*smax) + 1 - SvIV(*smin);
            newsize *= length;
        }
        if(!resize_needed)
            goto skip;
        // allocate the new torus buffer
        Newxz(newtorusbuf, newsize, IV);
        snewtorus = newSVpvn(newtorusbuf, newsize * sizeof(IV));
        Safefree(newtorusbuf);
        newivptr = (IV*)SvPV(snewtorus, newsize);
        // set "point" to our new min value
        for(i = 0; i < nd; i++) {
            SV **smin = av_fetch(amin, i, 0);
            av_store(apoint, i, newSViv(SvIV(*smin)));
        }
        // populate the new torus
        while(apoint) {
            int notyet = 0, never = 0, oldoffset, newoffset;
            SV **smax_0, **spoint_0, *newspoint_0;
            IV max_0, point_0;
            for(i = 0; i < nd; i++) {
                SV **soldmin, **soldmax;
                spoint_0 = av_fetch(apoint , i, 0);
                soldmin  = av_fetch(aoldmin, i, 0);
                soldmax  = av_fetch(aoldmax, i, 0);
                if(SvIV(*spoint_0) < SvIV(*soldmin)) {
                    if(i) {
                        // this row will never intersect; fill the whole thing.
                        never = 1;
                        break;
                    } else {
                        notyet = 1;
                    }
                }
                if(SvIV(*spoint_0) > SvIV(*soldmax)) {
                    never = 1;
                    break;
                }
            }
            spoint_0 = av_fetch(apoint, 0, 0);
            if(never) {
                // skip the rest of this row.
                smax_0 = av_fetch(amax, 0, 0);
                max_0 = SvIV(*smax_0);
                point_0 = SvIV(*spoint_0);
                debug("expand: never offset\n");
                newoffset = _Aoffset(nd, apoint, amin, amax);
                while(point_0 <= max_0) {
                    newivptr[newoffset++] = filler;
                    point_0++;
                }
                newspoint_0 = newSViv(point_0);
                av_store(apoint, 0, newspoint_0);
                spoint_0 = av_fetch(apoint, 0, 0);
            }
            if(notyet) {
                // skip forward along this row until we get to the valid data
                SV **sold_0 = av_fetch(aoldmin, 0, 0);
                IV old_0 = SvIV(*sold_0);
                spoint_0 = av_fetch(apoint, 0, 0);
                point_0 = SvIV(*spoint_0);
                debug("expand: notyet offset (%i .. %i)\n",point_0,old_0);
                newoffset = _Aoffset(nd, apoint, amin, amax);
                while(point_0 < old_0) {
                    newivptr[newoffset++] = filler;
                    point_0++;
                }
                newspoint_0 = newSViv(point_0);
                av_store(apoint, 0, newspoint_0);
                spoint_0 = av_fetch(apoint, 0, 0);
            }
            smax_0 = av_fetch(aoldmax, 0, 0);
            max_0 = SvIV(*smax_0);
            spoint_0 = av_fetch(apoint, 0, 0);
            point_0 = SvIV(*spoint_0);
            if(point_0 <= max_0) {
                debug("expand: old offset: point_0=%i max_0=%i never=%i notyet=%i\n",point_0,max_0,never,notyet);
                oldoffset = _Aoffset(nd, apoint, aoldmin, aoldmax);
                debug("expand: new offset\n");
                newoffset = _Aoffset(nd, apoint, amin, amax);
                while(max_0 >= point_0) {
                    // copy data until the end of the row
                    newivptr[newoffset++] = oldivptr[oldoffset++];
                    point_0++;
                }
                point_0--;
            }
            newspoint_0 = newSViv(point_0);
            av_store(apoint, 0, newspoint_0);
            do_rasterize(&point, min, max, &apoint, amin, amax);
        }
    skip:
        RETVAL = storus;
    done:
        RETVAL = snewtorus;
        FREETMPS;
        LEAVE;
    OUTPUT:
        RETVAL

SV*
_call_rasterize_perl( vec, min, max )
        SV *vec;
        SV *min;
        SV *max;
    CODE:
        RETVAL = call_rasterize_perl(vec, min, max);
    OUTPUT:
        RETVAL
