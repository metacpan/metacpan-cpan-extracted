/* -*- c -*- 
 * File: calc.c
 * $Id$
 */

#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "pmiscdef.h"
#include "tmplpro.h" /* for tmplpro_version */

#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#ifndef HAVE_DRAND48
#define drand48() (((float) rand())/((float) RAND_MAX))
#define srand48(x) (srand((x)))
#endif


static
const symrec_const *
getsym (const symrec_const symrec_array[], PSTRING sym_name)
{
  long int len = sym_name.endnext-sym_name.begin;
  const symrec_const* ptr;
  for (ptr=symrec_array; ptr->name!=NULL; ptr++) 
    if (len == ptr->len && strncmp (ptr->name,sym_name.begin,len) == 0)
      return ptr;
  return 0;
}

#define ABS(X) (((X)<0)? (-X) : (X))

static 
struct exprval builtin_int (struct expr_parser* exprobj, struct exprval e) {
  expr_to_int1(exprobj, &e);
  return e;
}

static 
struct exprval builtin_abs (struct expr_parser* exprobj, struct exprval e) {
  expr_to_int_or_dbl1(exprobj, &e);
  if (e.type==EXPR_TYPE_DBL) e.val.dblval = ABS(e.val.dblval);
  else if (e.type==EXPR_TYPE_INT) e.val.intval = ABS(e.val.intval);
  return e;
}

static 
struct exprval builtin_defined (struct expr_parser* exprobj, struct exprval e) {
  struct exprval retval =  NEW_EXPRVAL(EXPR_TYPE_INT);
  if (e.type==EXPR_TYPE_NULL || 
      (e.type==EXPR_TYPE_PSTR && e.val.strval.begin == NULL)) retval.val.intval = 0;
  else retval.val.intval = 1;
  return retval;
}

static 
struct exprval builtin_length (struct expr_parser* exprobj, struct exprval e) {
  struct exprval retval = NEW_EXPRVAL(EXPR_TYPE_INT);
  expr_to_str1(exprobj->state, &e);
  retval.val.intval = (EXPR_int64) (e.val.strval.endnext - e.val.strval.begin);
  return retval;
}

static 
struct exprval builtin_hex (struct expr_parser* exprobj, struct exprval e) {
  struct exprval retval = NEW_EXPRVAL(EXPR_TYPE_INT);
  unsigned int scan = 0;
  expr_to_str1(exprobj->state, &e);
  if (e.val.strval.begin!=NULL) sscanf(e.val.strval.begin, "%x", &scan);
  retval.val.intval = scan;
  return retval;
}

static 
struct exprval builtin_oct (struct expr_parser* exprobj, struct exprval e) {
  struct exprval retval = NEW_EXPRVAL(EXPR_TYPE_INT);
  unsigned int scan = 0;
  expr_to_str1(exprobj->state, &e);
  if (e.val.strval.begin!=NULL) sscanf(e.val.strval.begin, "%o", &scan);
  retval.val.intval = scan;
  return retval;
}

static int _srand_called = 0;

static 
struct exprval builtin_srand (struct expr_parser* exprobj, struct exprval e) {
  struct exprval retval = NEW_EXPRVAL(EXPR_TYPE_DBL);
  expr_to_int1(exprobj, &e);
  if (e.val.intval == 0) {
    e.val.intval=clock();
  }
  srand48(e.val.intval);
  _srand_called = 1;
  retval.val.dblval = 0;
  return retval;
}

static 
struct exprval builtin_rand (struct expr_parser* exprobj, struct exprval e) {
  struct exprval retval = NEW_EXPRVAL(EXPR_TYPE_DBL);
  if (EXPR_TYPE_PSTR == e.type && NULL == e.val.strval.begin) {
    e.type = EXPR_TYPE_DBL;
    e.val.dblval = 1.0;
  }
  expr_to_dbl1(exprobj, &e);
  if (!_srand_called) srand48(clock());
  retval.val.dblval = drand48() * e.val.dblval;
  return retval;
}

static 
struct exprval builtin_version (struct expr_parser* exprobj, struct exprval e) {
  struct exprval retval = NEW_EXPRVAL(EXPR_TYPE_PSTR);
  retval.val.strval.begin = tmplpro_version();
  retval.val.strval.endnext = retval.val.strval.begin + strlen(retval.val.strval.begin);
  return retval;
}
