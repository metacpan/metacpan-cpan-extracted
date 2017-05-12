/* 
 * File: expr_iface.c
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Sat Apr 15 21:15:24 2006
 */

#include <string.h>
#include "tmplpro.h"
#include "exprval.h"
#include "pparam.h"

API_IMPL 
void 
APICALL
tmplpro_set_expr_as_int64 (struct exprval* p,EXPR_int64 ival) {
  p->type=EXPR_TYPE_INT;
  p->val.intval=ival;
}

API_IMPL 
void 
APICALL
tmplpro_set_expr_as_double (struct exprval* p,double dval) {
  p->type=EXPR_TYPE_DBL;
  p->val.dblval=dval;
}

API_IMPL 
void 
APICALL
tmplpro_set_expr_as_string (struct exprval* p, const char* sval) {
  p->type=EXPR_TYPE_PSTR;
  p->val.strval.begin=sval;
  p->val.strval.endnext=sval;
  if (NULL!=sval) p->val.strval.endnext+=strlen(sval);
}

API_IMPL 
void 
APICALL
tmplpro_set_expr_as_pstring (struct exprval* p,PSTRING pval) {
  p->type=EXPR_TYPE_PSTR;
  p->val.strval=pval;
}

API_IMPL 
void 
APICALL
tmplpro_set_expr_as_null (struct exprval* p) {
  p->type=EXPR_TYPE_PSTR;
  p->val.strval.begin=NULL;
  p->val.strval.endnext=NULL;
}

API_IMPL 
int
APICALL
tmplpro_get_expr_type (struct exprval* p) {
  if (p->type == EXPR_TYPE_PSTR) {
    if (NULL==p->val.strval.begin) {
      p->val.strval.endnext=NULL;
      p->type = EXPR_TYPE_NULL;
    } else if (NULL==p->val.strval.endnext) {
      /* should never happen */
      p->val.strval.endnext=p->val.strval.begin+strlen(p->val.strval.begin);
    }
  /* never happen; but let it be for future compatibility */
  } else if (p->type == EXPR_TYPE_NULL) {
      p->val.strval.begin=NULL;
      p->val.strval.endnext=NULL;
  }
  return (int) p->type;
}

API_IMPL 
EXPR_int64 
APICALL
tmplpro_get_expr_as_int64 (struct exprval* p) {
  return p->val.intval;
}

API_IMPL 
double
APICALL
tmplpro_get_expr_as_double (struct exprval* p) {
  return p->val.dblval;
}

API_IMPL 
PSTRING
APICALL
tmplpro_get_expr_as_pstring (struct exprval* p) {
  return p->val.strval;
}
