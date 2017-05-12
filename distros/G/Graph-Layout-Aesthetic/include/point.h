/* point manipulation routines */
/* $Id: point.h,v 1.1 1993/05/26 23:22:27 coleman Exp $ */

#ifndef point_h
#define point_h

#include "aglo.h"

void aglo_point_add(aglo_unsigned d, aglo_point result, aglo_const_point arg1, aglo_const_point arg2);
void aglo_point_sub(aglo_unsigned d, aglo_point result, aglo_const_point arg1, aglo_const_point arg2);
void aglo_point_inc(aglo_unsigned d, aglo_point result, aglo_const_point arg);
void aglo_point_dec(aglo_unsigned d, aglo_point result, aglo_const_point arg);
aglo_real aglo_point_mag(aglo_unsigned d,  aglo_const_point arg);
aglo_real aglo_point_mag2(aglo_unsigned d, aglo_const_point arg);
void aglo_point_midpoint(aglo_unsigned d, aglo_point result, aglo_const_point arg1, aglo_const_point arg2);
void aglo_point_scalar_mult(aglo_unsigned d, aglo_point result, aglo_real scalar_arg,
                            aglo_const_point point_arg);
aglo_real aglo_point_dot_product(aglo_unsigned d, 
                                 aglo_const_point arg1,
                                 aglo_const_point arg2);
void aglo_point_assign(aglo_unsigned d, aglo_point result, aglo_const_point arg);
void aglo_point_zero(aglo_unsigned d, aglo_point result);

#endif
