/* -*- c -*- 
 * File: exprval.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Mon Jul 20 21:10:57 2009
 */

#ifndef _EXPRVAL_H
#define _EXPRVAL_H	1

#include "exprtype.h"

typedef char EXPR_char;
struct exprval {
  EXPR_char type;
  union uval {
    EXPR_int64  intval; 	/* integer */
    double dblval;		/* double */
    PSTRING strval;
  } val;
};

#define NEW_EXPRVAL(X) { X }

#endif /* exprval.h */

/*
 *  Local Variables:
 *  mode: c
 *  End:
 */
