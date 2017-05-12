/* -*- c -*- 
 * File: pstring.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Fri Jul  1 20:11:51 2005
 *
 * $Id$
 */

#ifndef _EXPR_TYPE_PSTR_H
#define _EXPR_TYPE_PSTR_H	1

#include "exprval.h"

static
PSTRING double_to_pstring (double, char* buf, size_t bufsize);
static
PSTRING int_to_pstring (EXPR_int64, char* buf, size_t bufsize);
static
int pstring_ge(PSTRING, PSTRING);
static
int pstring_le(PSTRING, PSTRING);
static
int pstring_ne(PSTRING, PSTRING);
static
int pstring_eq(PSTRING, PSTRING);
static
int pstring_gt(PSTRING, PSTRING);
static
int pstring_lt(PSTRING, PSTRING);

static
int re_like(struct expr_parser* exprobj, PSTRING, PSTRING);
static
int re_notlike(struct expr_parser* exprobj, PSTRING, PSTRING);

#endif /* exprpstr.h */
