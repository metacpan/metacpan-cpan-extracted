/* -*- Mode: C -*- */

#define PERL_NO_GET_CONTEXT 1

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "mvr.h"
#include <math.h>

MODULE = Math::Vector::Real::XS		PACKAGE = Math::Vector::Real		
PROTOTYPES: DISABLE

BOOT:
    mvr_on_boot(aTHX);

void
CLONE(...)
CODE:
    mvr_on_clone(aTHX);

mvr 
V(...)
PREINIT:
    I32 i;
CODE:
    RETVAL = mvr_new(aTHX_ items - 1);
    for (i = 0; i < items; i++)
        mvr_set(aTHX_ RETVAL, i, SvNV(ST(i)));
OUTPUT:
    RETVAL

mvr 
zero(klass, dim)
    SV *klass = NO_INIT
    I32 dim
PREINIT:
    I32 i;
CODE:
    if (dim < 0) Perl_croak(aTHX_ "negative dimension");
    RETVAL = mvr_new(aTHX_ dim - 1);
    for (i = 0; i < dim; i++)
        mvr_set(aTHX_ RETVAL, i, 0);
OUTPUT:
    RETVAL

mvr 
axis_versor(klass, dim, axis)
    SV *klass = NO_INIT
    I32 dim
    I32 axis
CODE:
    if (dim < 0) Perl_croak(aTHX_ "negative_dimension");
    if ((axis < 0) || (axis >= dim)) Perl_croak(aTHX_ "axis index out of range");
    RETVAL = mvr_new(aTHX_ dim - 1);
    mvr_axis_versor(aTHX_ dim - 1, axis, RETVAL);
OUTPUT:
    RETVAL

mvr 
add(v0, v1, rev = 0)
    mvr v0
    mvr v1
    SV *rev = NO_INIT
PREINIT:
    I32 len, i;
CODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    RETVAL = mvr_new(aTHX_ len);
    mvr_add(aTHX_ v0, v1, len, RETVAL);
OUTPUT:
    RETVAL

void
add_me(v0, v1, rev = 0)
    mvr v0
    mvr v1
    SV *rev = NO_INIT
PREINIT:
    I32 len, i;
PPCODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    mvr_add_me(aTHX_ v0, v1, len);
    XSRETURN(1);

mvr 
neg(v, v1 = 0, rev = 0)
    mvr v
    SV *v1 = NO_INIT
    SV *rev = NO_INIT
PREINIT:
    I32 len, i;
CODE:
    len = mvr_len(aTHX_ v);
    RETVAL = mvr_new(aTHX_ len);
    mvr_neg(aTHX_ v, len, RETVAL);
OUTPUT:
    RETVAL

mvr 
sub(v0, v1, rev = &PL_sv_undef)
    mvr v0
    mvr v1
    SV *rev
PREINIT:
    I32 len, i;
CODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    if (SvTRUE(rev)) {
        mvr tmp = v1;
        v1 = v0;
        v0 = tmp;
    }
    RETVAL = mvr_new(aTHX_ len);
    mvr_subtract(aTHX_ v0, v1, len, RETVAL);
OUTPUT:
    RETVAL

void
sub_me(v0, v1, rev = 0)
    mvr v0
    mvr v1
    SV *rev = NO_INIT
PREINIT:
    I32 len, i;
PPCODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    mvr_subtract_me(aTHX_ v0, v1, len);
    XSRETURN(1);

void
mul(v0, sv1, rev = 0)
    mvr v0;
    SV *sv1
    SV *rev = NO_INIT
PREINIT:
    I32 len, i;
    mvr v1;
PPCODE:
    /* fprintf(stderr, "using mul operator from XS\n"); fflush(stderr); */
    len = mvr_len(aTHX_ v0);
    if (SvROK(sv1) && (SvTYPE(v1 = (AV*)SvRV(sv1)) == SVt_PVAV)) {
        NV acu = 0;
        mvr_check_len(aTHX_ v1, len);
        ST(0) = sv_2mortal(newSVnv(mvr_dot_product(aTHX_ v0, v1, len)));
        XSRETURN(1);
    }
    else {
        mvr r = mvr_new(aTHX_ len);
        mvr_scalar_product(aTHX_ v0, SvNV(sv1), len, r);
        ST(0) = sv_newmortal();
        sv_set_mvr(aTHX_ ST(0), r);
        XSRETURN(1);
    }

void
mul_me(v0, sv1, rev = 0)
    mvr v0
    SV *sv1
    SV *rev = NO_INIT
PREINIT:
    int len, i;
    NV nv1;
PPCODE:
    if (SvROK(sv1) && (SvTYPE(SvRV(sv1)) == SVt_PVAV))
        Perl_croak(aTHX_ "can not multiply by a vector in place as the result is not a vector");
    nv1 = SvNV(sv1);
    len = mvr_len(aTHX_ v0);
    for (i = 0; i <= len; i++) {
        SV *sv = mvr_get_sv(aTHX_ v0, i);
        sv_setnv(sv, nv1 * SvNV(sv));
    }
    XSRETURN(1);

mvr 
div(v0, sv1, rev = &PL_sv_undef)
    mvr v0
    SV *sv1
    SV *rev
PREINIT:
    NV nv1;
    I32 len, i;
CODE:
    if (SvTRUE(rev) || (SvROK(sv1) && (SvTYPE(SvRV(sv1)) == SVt_PVAV)))
        Perl_croak(aTHX_ "can't use vector as dividend");
    nv1 = SvNV(sv1);
    if (nv1 == 0)
        Perl_croak(aTHX_ "illegal division by zero");
    len = mvr_len(aTHX_ v0);
    RETVAL = mvr_new(aTHX_ len);
    mvr_scalar_product(aTHX_ v0, 1.0 / nv1, len, RETVAL);
OUTPUT:
    RETVAL

void
div_me(v0, sv1, rev = 0)
    mvr v0
    SV *sv1
    SV *rev = NO_INIT
PREINIT:
    int len, i;
    NV nv1, inv1;
CODE:
    if (SvROK(sv1) && (SvTYPE(SvRV(sv1)) == SVt_PVAV))
        Perl_croak(aTHX_ "can't use vector as dividend");
    nv1 = SvNV(sv1);
    if (nv1 == 0) Perl_croak(aTHX_ "illegal division by zero");
    mvr_scalar_product_me(aTHX_ v0, 1.0 / nv1, mvr_len(aTHX_ v0));
    XSRETURN(1);

mvr 
cross(v0, v1, rev = &PL_sv_undef)
    mvr v0
    mvr v1
    SV *rev
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v0);
    if (len == 2) {
        mvr_check_len(aTHX_ v1, 2);
        if (SvTRUE(rev)) {
            mvr tmp = v0;
            v0 = v1;
            v1 = tmp;
        }
        RETVAL = mvr_new(aTHX_ 2);
        mvr_cross_product_3d(aTHX_ v0, v1, RETVAL);
    }
    else {
        Perl_croak(aTHX_ "cross product not defined or not implemented for the given dimension");
    }
OUTPUT:
    RETVAL

SV *
equal(v0, v1, rev = 0)
    mvr v0
    mvr v1
    SV *rev = NO_INIT
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    RETVAL = (mvr_equal(aTHX_ v0, v1, len) ? &PL_sv_yes : &PL_sv_no);
OUTPUT:
    RETVAL
            
SV *
nequal(v0, v1, rev = 0)
    mvr v0
    mvr v1
    SV *rev = NO_INIT
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    RETVAL = (mvr_equal(aTHX_ v0, v1, len) ? &PL_sv_no : &PL_sv_yes);
OUTPUT:
    RETVAL
            
NV
abs(v, v1 = 0, rev = 0)
    mvr v
    SV *v1 = NO_INIT
    SV *rev = NO_INIT
CODE:
    RETVAL = mvr_norm(aTHX_ v, mvr_len(aTHX_ v));
OUTPUT:
    RETVAL

NV
abs2(v)
    mvr v
CODE:    
    RETVAL = mvr_norm2(aTHX_ v, mvr_len(aTHX_ v));
OUTPUT:
    RETVAL

NV
manhattan_norm(v)
    mvr v
CODE:
    RETVAL = mvr_manhattan_norm(aTHX_ v, mvr_len(aTHX_ v));
OUTPUT:
    RETVAL

NV
dist2(v0, v1)
    mvr v0
    mvr v1
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    RETVAL = mvr_dist2(aTHX_ v0, v1, len);
OUTPUT:
    RETVAL

NV
dist(v0, v1)
    mvr v0
    mvr v1
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    RETVAL = mvr_dist(aTHX_ v0, v1, len);
OUTPUT:
    RETVAL

NV
manhattan_dist(v0, v1)
    mvr v0
    mvr v1
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    RETVAL = mvr_manhattan_dist(aTHX_ v0, v1, len);
OUTPUT:
    RETVAL

NV
chebyshev_dist(v0, v1)
     mvr v0
     mvr v1
PREINIT:
     I32 len;
CODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    RETVAL = mvr_chebyshev_dist(aTHX_ v0, v1, len);
OUTPUT:
    RETVAL

mvr 
versor(v)
    mvr v
PREINIT:
    I32 len, i;
    NV n;
CODE:
    len = mvr_len(aTHX_ v);
    n = mvr_norm(aTHX_ v, len);
    if (n == 0) Perl_croak(aTHX_ "Illegal division by zero");
    RETVAL = mvr_new(aTHX_ len);
    mvr_scalar_product(aTHX_ v, 1.0 / n, len, RETVAL);
OUTPUT:
    RETVAL

SV *
max_component_index(v)
    mvr v
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v);
    if (len < 0) RETVAL = &PL_sv_undef;
    else RETVAL = newSViv(mvr_max_component_index(aTHX_ v, len));
OUTPUT:
    RETVAL

SV *
min_component_index(v)
    mvr v
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v);
    if (len < 0) RETVAL = &PL_sv_undef;
    else RETVAL = newSViv(mvr_min_component_index(aTHX_ v, len));
OUTPUT:
   RETVAL

NV
max_component(v)
    mvr v
PREINIT:
    I32 len, i;
CODE:
    len = mvr_len(aTHX_ v);
    for (RETVAL = 0, i = 0; i <= len; i++) {
        NV c = fabs(mvr_get(aTHX_ v, i));
        if (c > RETVAL) RETVAL = c;
    }
OUTPUT:
    RETVAL

NV
min_component(v)
    mvr v
PREINIT:
    I32 len, i;
CODE:
    len = mvr_len(aTHX_ v);
    RETVAL = fabs(mvr_get(aTHX_ v, 0));
    for (i = 1; i <= len; i++) {
        NV c = fabs(mvr_get(aTHX_ v, i));
        if (c < RETVAL) RETVAL = c;
    }
OUTPUT:
    RETVAL

mvr
first_orthant_reflection(v)
    mvr v
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ v);
    RETVAL = mvr_new(aTHX_ len);
    mvr_first_orthant_reflection(aTHX_ v, len, RETVAL);
OUTPUT:
    RETVAL

NV
dist2_to_box(v, w0, ...)
    mvr v
    mvr w0 = NO_INIT
PREINIT:
    I32 len, i, j;
CODE:
    len = mvr_len(aTHX_ v);
    RETVAL = 0;
    for (j = 1; j < items; j++) {
        mvr w = mvr_from_sv(aTHX_ ST(j));
	mvr_check_len(aTHX_ w, len);
    }
    for (i = 0; i <= len; i++) {
	NV c_min = INFINITY;
        NV c_max = -INFINITY;
        NV c;
	for (j = 1; j < items; j++) {
	    mvr w = mvr_from_sv(aTHX_ ST(j));
	    c = mvr_get(aTHX_ w, i);
	    c_min = (c < c_min ? c : c_min);
	    c_max = (c > c_max ? c : c_max);
	}
        c = mvr_get(aTHX_ v, i);
        if (c < c_min) {
            NV d = c_min - c;
            RETVAL += d * d;
        }
        if (c > c_max) {
            NV d = c_max - c;
            RETVAL += d * d;
        }
    }
OUTPUT:
    RETVAL

NV
max_dist2_to_box(v, w0, ...)
    mvr v
    mvr w0 = NO_INIT
PREINIT:
    I32 len, i, j;
CODE:
    len = mvr_len(aTHX_ v);
    RETVAL = 0;
    for (j = 1; j < items; j++) {
	mvr w = mvr_from_sv(aTHX_ ST(j));
	mvr_check_len(aTHX_ w, len);
    }
    for (i = 0; i <= len; i++) {
	NV c = mvr_get(aTHX_ v, i);
	NV max_d = 0;
	for (j = 1; j < items; j++) {
	    mvr w = mvr_from_sv(aTHX_ ST(j));
	    NV d = fabs(mvr_get(aTHX_ w, i) - c);
	    max_d = (d > max_d ? d : max_d);
	}
	RETVAL += max_d * max_d;
    }
OUTPUT:
    RETVAL

NV
dist2_between_boxes(klass, a0, a1, b0, b1)
    SV *klass = NO_INIT
    mvr a0
    mvr a1
    mvr b0
    mvr b1
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ a0);
    mvr_check_len(aTHX_ a1, len);
    mvr_check_len(aTHX_ b0, len);
    mvr_check_len(aTHX_ b1, len);
    RETVAL = mvr_dist2_between_boxes(aTHX_ a0, a1, b0, b1, len);
OUTPUT:
    RETVAL

NV
max_dist2_between_boxes(klass, a0, a1, b0, b1)
    SV *klass = NO_INIT
    mvr a0
    mvr a1
    mvr b0
    mvr b1
PREINIT:
    I32 len;
CODE:
    len = mvr_len(aTHX_ a0);
    mvr_check_len(aTHX_ a1, len);
    mvr_check_len(aTHX_ b0, len);
    mvr_check_len(aTHX_ b1, len);
    RETVAL = mvr_max_dist2_between_boxes(aTHX_ a0, a1, b0, b1, len);
OUTPUT:
    RETVAL

mvr
sum(klass, ...)
    SV *klass;
PREINIT:
    I32 i, j, len;
CODE:
    i = (SvROK(klass) ? 0 : 1);
    if (items > i) {
	mvr v = mvr_from_sv(aTHX_ ST(i));
	len = mvr_len(aTHX_ v);
	RETVAL = mvr_clone(aTHX_ v, len);
	for (i++; i < items; i++) {
	    v = mvr_from_sv(aTHX_ ST(i));
	    mvr_check_len(aTHX_ v, len);
	    for (j = 0; j <= len; j++) {
		SV *sv = mvr_get_sv(aTHX_ RETVAL, j);
		sv_setnv(sv, SvNV(sv) + mvr_get(aTHX_ v, j));
	    }
	}
    }
    else {
	XSRETURN(0);
    }
OUTPUT:
    RETVAL

void
box(klass, ...)
    SV *klass = NO_INIT
PPCODE:
    if (items <= 1) XSRETURN(0);
    else {
        I32 len, j;
        mvr min, max;
        mvr v = mvr_from_sv(aTHX_ ST(1));
        len = mvr_len(aTHX_ v);
        min = mvr_clone(aTHX_ v, len);
        max = mvr_clone(aTHX_ v, len);
        for (j = 2; j < items; j++) {
            I32 i;
            v = mvr_from_sv(aTHX_ ST(j));
            mvr_check_len(aTHX_ v, len);
            for (i = 0; i <= len; i++) {
                NV c = mvr_get(aTHX_ v, i);
                SV *sv = mvr_get_sv(aTHX_ max, i);
                if (c > SvNV(sv)) sv_setnv(sv, c);
                else {
                    sv = mvr_get_sv(aTHX_ min, i);
                    if (c < SvNV(sv)) sv_setnv(sv, c);
                }
            }
        }
        EXTEND(SP, 2);
        ST(0) = sv_newmortal();
        sv_set_mvr(aTHX_ ST(0), min);
        ST(1) = sv_newmortal();
        sv_set_mvr(aTHX_ ST(1), max);
        XSRETURN(2);
    }

void
decompose(v0, v1)
    mvr v0
    mvr v1
PREINIT:
    I32 len, i;
    mvr p, n;
    NV f, nr;
PPCODE:
    len = mvr_len(aTHX_ v0);
    mvr_check_len(aTHX_ v1, len);
    nr = mvr_norm(aTHX_ v0, len);
    if (nr == 0) Perl_croak(aTHX_ "Illegal division by zero");
    p = mvr_new(aTHX_ len);
    mvr_scalar_product(aTHX_ v0, mvr_dot_product(aTHX_ v0, v1, len) / nr, len, p);
    if (GIMME_V == G_ARRAY) {
        n = mvr_new(aTHX_ len);
        mvr_subtract(aTHX_ v1, p, len, n);
        EXTEND(SP, 2);
        ST(0) = sv_newmortal();
        sv_set_mvr(aTHX_ ST(0), p);
        ST(1) = sv_newmortal();
        sv_set_mvr(aTHX_ ST(1), n);
        XSRETURN(2);
    }
    else {
        mvr_subtract_and_neg_me(aTHX_ p, v1, len);
        ST(0) = sv_newmortal();
        sv_set_mvr(aTHX_ ST(0), p);
        XSRETURN(1);
    }

void
canonical_base(klass, dim)
    SV *klass = NO_INIT
    I32 dim
PREINIT:
    I32 j;
PPCODE:
    if (dim <= 0) Perl_croak(aTHX_ "negative dimension");
    EXTEND(SP, dim);
    for (j = 0; j < dim; j++) {
        mvr v = mvr_new(aTHX_ dim - 1);
        ST(j) = sv_newmortal();
        sv_set_mvr(aTHX_ ST(j), v);
        mvr_axis_versor(aTHX_ dim - 1, j, v);
    }
    XSRETURN(dim);

void
rotation_base_3d(dir)
    mvr dir
PREINIT:
    I32 len, i;
    mvr u, v, w;
    NV n;
PPCODE:
    len = mvr_len(aTHX_ dir);
    if (len != 2) Perl_croak(aTHX_ "rotation_base_3d requires a 3D vector");
    n = mvr_norm(aTHX_ dir, len);
    if (n == 0) Perl_croak(aTHX_ "Illegal division by zero");
    EXTEND(SP, 3);
    u = mvr_new(aTHX_ 2);
    ST(0) = sv_newmortal();
    sv_set_mvr(aTHX_ ST(0), u);
    v = mvr_new(aTHX_ 2);
    ST(1) = sv_newmortal();
    sv_set_mvr(aTHX_ ST(1), v);
    w = mvr_new(aTHX_ 2);
    ST(2) = sv_newmortal();
    sv_set_mvr(aTHX_ ST(2), w);
    mvr_scalar_product(aTHX_ dir, 1.0 / n, len, u);
    mvr_axis_versor(aTHX_ len, mvr_min_component_index(aTHX_ u, len), w);
    mvr_cross_product_3d(aTHX_ u, w, v);
    mvr_versor_me_unsafe(aTHX_ v, len);
    mvr_cross_product_3d(aTHX_ u, v, w);
    XSRETURN(3);



void
select_in_ball(v, r, ...)
    mvr v
    NV r
PREINIT:
    I32 len, i, to;
    NV r2;
PPCODE:
    len = mvr_len(aTHX_ v);
    r2 = r * r;
    for (to = 0, i = 2; i < items; i++) {
        mvr e = mvr_from_sv(aTHX_ ST(i));
        mvr_check_len(aTHX_ e, len);
        if (mvr_dist2(aTHX_ v, e, len) <= r2) {
            ST(to) = sv_newmortal();
            sv_set_mvr(aTHX_ ST(to), mvr_clone(aTHX_ e, len));
            to++;
        }
    }
    XSRETURN(to);

SV *
select_in_ball_ref2bitmap(v, r, p)
    mvr v
    NV r
    AV *p
PREINIT:
    I32 len, size, bytes, i;
    unsigned char bit;
    NV r2;
    unsigned char *pv;
CODE:
    len = mvr_len(aTHX_ v);
    r2 = r * r;
    size = av_len(p);
    bytes = (size + 7) / 8;
    RETVAL = newSV((size + 7) / 8);
    SvPOK_on(RETVAL);
    SvCUR_set(RETVAL, bytes);
    pv = SvPVX(RETVAL);
    memset(pv, 0, bytes);
    for (bit = 1, i = 0; i < size; i++) {
        SV **svp = av_fetch(p, i, 0);
        mvr e;
        if (!svp) Perl_croak(aTHX_ "undef element found in array");
        e = mvr_from_sv(aTHX_ *svp);
        mvr_check_len(aTHX_ e, len);
        if (mvr_dist2(aTHX_ v, e, len) <= r2) *pv |= bit;
        bit <<= 1;
        if (!bit) {
            pv++;
            bit = 1;
        }
    }
OUTPUT:
    RETVAL
