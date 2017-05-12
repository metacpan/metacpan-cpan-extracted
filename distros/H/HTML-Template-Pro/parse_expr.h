/* -*- c -*- 
 * File: parse_expr.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Mon Jun  6 14:54:45 2005
 */

#ifndef _PARSE_EXPR_H
#define _PARSE_EXPR_H	1

#include<pabidecl.h>

TMPLPRO_LOCAL
PSTRING parse_expr(PSTRING line, struct tmplpro_state* state);

#endif /* parse_expr.h */
