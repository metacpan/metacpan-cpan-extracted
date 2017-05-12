/* -*- c -*- 
 * File: exprtool.h
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Mon Jul 25 15:29:04 2005
 *
 * $Id$
 */

#ifndef _EXPRTOOL_H
#define _EXPRTOOL_H	1

#include "pstring.h"
#include "exprval.h"

struct expr_parser {
  struct tmplpro_state* state;
  PSTRING exprarea;
  const char* expr_curpos;
  /* for callbacks */
  struct exprval userfunc_call;
  /* 
   * is_expect_quote_like allows recognization of quotelike.
   * if not is_expect_quote_like we look only for 'str' and, possibly, "str"
   * if is_expect_quote_like we also look for /str/.
   */
  int is_expect_quote_like;
  /* 
   * is_tt_like_logical: if set, && and || behave like in TemplateToolkit
   */
  int is_tt_like_logical;
};

#define DO_MATHOP(exprobj, z,op,x,y) switch (z.type=expr_to_int_or_dbl(exprobj, &x,&y)) { \
case EXPR_TYPE_INT: z.val.intval=x.val.intval op y.val.intval;break; \
case EXPR_TYPE_DBL: z.val.dblval=x.val.dblval op y.val.dblval;break; \
}

#define DO_LOGOP(exprobj, z,op,x,y) z.type=EXPR_TYPE_INT; switch (expr_to_int_or_dbl_logop(exprobj, &x,&y)) { \
case EXPR_TYPE_INT: z.val.intval=x.val.intval op y.val.intval;break; \
case EXPR_TYPE_DBL: z.val.intval=x.val.dblval op y.val.dblval;break; \
}

#define DO_LOGOP1(exprobj,z,op,x) z.type=EXPR_TYPE_INT; switch (expr_to_int_or_dbl_logop1(exprobj, &x)) { \
case EXPR_TYPE_INT: z.val.intval= op x.val.intval;break; \
case EXPR_TYPE_DBL: z.val.intval= op x.val.dblval;break; \
}

#define DO_CMPOP(exprobj, z,op,x,y) switch (expr_to_int_or_dbl(exprobj, &x,&y)) { \
case EXPR_TYPE_INT: z.val.intval=x.val.intval op y.val.intval;break; \
case EXPR_TYPE_DBL: z.val.intval=x.val.dblval op y.val.dblval;break; \
}; z.type=EXPR_TYPE_INT;

#define DO_TXTOP(z,op,x,y,buf) expr_to_str(buf, &x,&y); z.type=EXPR_TYPE_INT; z.val.intval = op (x.val.strval,y.val.strval);
#define DO_TXTOPLOG(z,op,x,y,exprobj) expr_to_str(exprobj->state, &x,&y); z.type=EXPR_TYPE_INT; z.val.intval = op (exprobj,x.val.strval,y.val.strval);

static
EXPR_char expr_to_int_or_dbl (struct expr_parser* exprobj, struct exprval* val1, struct exprval* val2);
static
EXPR_char expr_to_int_or_dbl1 (struct expr_parser* exprobj, struct exprval* val1);
static
EXPR_char expr_to_int_or_dbl_logop (struct expr_parser* exprobj, struct exprval* val1, struct exprval* val2);
static
EXPR_char expr_to_int_or_dbl_logop1 (struct expr_parser* exprobj, struct exprval* val1);
static
void expr_to_dbl (struct expr_parser* exprobj, struct exprval* val1, struct exprval* val2);
static
void expr_to_int (struct expr_parser* exprobj, struct exprval* val1, struct exprval* val2);
static
void expr_to_dbl1 (struct expr_parser* exprobj, struct exprval* val);
static
void expr_to_int1 (struct expr_parser* exprobj, struct exprval* val1);
static
void expr_to_str (struct tmplpro_state* state, struct exprval* val1, struct exprval* val2);
static
void expr_to_str1 (struct tmplpro_state* state, struct exprval* val1);
static
void expr_to_num (struct expr_parser* exprobj, struct exprval* val1);
static
void expr_to_bool (struct expr_parser* exprobj, struct exprval* val1);
static
struct exprval exp_read_number (struct expr_parser* exprobj, const char* *curposptr, const char* endchars);

/* this stuff is defined or used in expr.y */
static
void log_expr(struct expr_parser* exprobj, int loglevel, const char* fmt, ...) FORMAT_PRINTF(3,4);

static
PSTRING expr_unescape_pstring_val(pbuffer* pbuff, PSTRING val);

static
void _tmplpro_expnum_debug (struct exprval val, char* msg);


struct user_func_call {
  ABSTRACT_USERFUNC* func;  /* for user-defined function name */
  ABSTRACT_ARGLIST* arglist;
};

static
struct exprval call_expr_userfunc(struct expr_parser* exprobj, struct tmplpro_param* param, struct user_func_call extfunc);
static
void pusharg_expr_userfunc(struct expr_parser* exprobj, struct tmplpro_param* param, struct user_func_call extfunc, struct exprval arg);

#endif /* exprtool.h */
