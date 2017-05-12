#define PERL_NO_GET_CONTEXT	/* we want efficiency */
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "at_centroid.h"
#include "point.h"

#include "defines.h"
#include "math.h"

void aglo_point_add(aglo_unsigned d, aglo_point result, 
                    aglo_const_point arg1, aglo_const_point arg2) {
    aglo_unsigned i;

    for (i=0;i<d;i++) result[i] = arg1[i] + arg2[i];
}

void aglo_point_sub(aglo_unsigned d, aglo_point result, 
                    aglo_const_point arg1, aglo_const_point arg2) {
    aglo_unsigned i;

    for (i=0; i<d; i++) result[i] = arg1[i] - arg2[i];
}

void aglo_point_inc(aglo_unsigned d, aglo_point result, aglo_const_point arg) {
    aglo_unsigned i;

    for (i=0;i<d;i++) result[i] += arg[i];
}

void aglo_point_dec(aglo_unsigned d, aglo_point result, aglo_const_point arg) {
    aglo_unsigned i;

    for (i=0;i<d;i++) result[i] -= arg[i];
}

aglo_real aglo_point_mag2(aglo_unsigned d, aglo_const_point arg) {
    aglo_unsigned i;
    aglo_real result = 0;
    for (i=0;i<d;i++) result += sqr(arg[i]);
    return result;
}

aglo_real aglo_point_mag(aglo_unsigned d, aglo_const_point arg) {
    return sqrt(aglo_point_mag2(d, arg));
}

void aglo_point_midpoint(aglo_unsigned d, aglo_point result, 
                         aglo_const_point arg1, aglo_const_point arg2) {
    aglo_unsigned i;

    for (i=0;i<d;i++) result[i] = (arg1[i] + arg2[i]) / 2;
}

void aglo_point_scalar_mult(aglo_unsigned d, aglo_point result, aglo_real scalar_arg,
                            aglo_const_point point_arg) {
    aglo_unsigned i;

    for (i=0;i<d;i++) result[i] = scalar_arg * point_arg[i];
}

aglo_real aglo_point_dot_product(aglo_unsigned d, 
                                 aglo_const_point arg1,
                                 aglo_const_point arg2) {
    aglo_unsigned i;
    aglo_real result = 0;
    for (i=0;i<d;i++) result += arg1[i] * arg2[i];
    return result;
}

void aglo_point_assign(aglo_unsigned d, aglo_point result, aglo_const_point arg) {
    Copy(arg, result, d, aglo_real);
}

void aglo_point_zero(aglo_unsigned d, aglo_point result) {
    aglo_unsigned i;

    for (i=0;i<d;i++) result[i] = 0;
}

MODULE = Graph::Layout::Aesthetic::Dummy::Point		PACKAGE = Graph::Layout::Aesthetic::Dummy
