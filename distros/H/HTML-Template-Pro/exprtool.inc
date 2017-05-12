/* -*- c -*- 
 * File: exprtool.c
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Mon Jul 25 15:29:17 2005
 *
 * $Id$
 */

/*
#include "exprtool.h"
#include <ctype.h> // for yylex alnum
#include <stdio.h> // for printf
*/

#define EXPR_CHECK_NUMBER(exprobj, ptr)   switch (ptr->type) {	\
  case EXPR_TYPE_INT: case EXPR_TYPE_DBL: break; \
  case EXPR_TYPE_UPSTR: case EXPR_TYPE_PSTR: expr_to_num(exprobj, ptr); break;	\
  default: _tmplpro_expnum_debug(*ptr, "FATAL:internal expr type error. please report\n"); \
  ptr->type = EXPR_TYPE_INT; \
}

#define EXPR_CHECK_LOGICAL(exprobj, ptr)   switch (ptr->type) {	\
  case EXPR_TYPE_INT: case EXPR_TYPE_DBL: break; \
  case EXPR_TYPE_UPSTR: case EXPR_TYPE_PSTR: expr_to_bool(exprobj, ptr); break;		\
  default: _tmplpro_expnum_debug(*ptr, "FATAL:internal expr type error. please report\n"); \
  ptr->type = EXPR_TYPE_INT; \
}

static
EXPR_char 
expr_to_int_or_dbl (struct expr_parser* exprobj, struct exprval* val1, struct exprval* val2) {
  EXPR_CHECK_NUMBER(exprobj, val1);
  EXPR_CHECK_NUMBER(exprobj, val2);
  if ((val1->type == EXPR_TYPE_INT) && (val2->type == EXPR_TYPE_INT))
    return EXPR_TYPE_INT;
  if ((val1->type == EXPR_TYPE_DBL) && (val2->type == EXPR_TYPE_DBL))
    return EXPR_TYPE_DBL;
  if (val1->type == EXPR_TYPE_INT) {
    val1->type=EXPR_TYPE_DBL;
    val1->val.dblval=(double) val1->val.intval;
  }
  if (val2->type == EXPR_TYPE_INT) {
    val1->type=EXPR_TYPE_DBL;
    val2->val.dblval=(double) val2->val.intval;
  }
  return EXPR_TYPE_DBL;
}

static
EXPR_char 
expr_to_int_or_dbl_logop (struct expr_parser* exprobj, struct exprval* val1, struct exprval* val2) {
  EXPR_CHECK_LOGICAL(exprobj, val1);
  EXPR_CHECK_LOGICAL(exprobj, val2);
  if (val1->type == EXPR_TYPE_INT && val2->type == EXPR_TYPE_INT)
    return EXPR_TYPE_INT;
  if (val1->type == EXPR_TYPE_DBL && val2->type == EXPR_TYPE_DBL)
    return EXPR_TYPE_DBL;
  if (val1->type == EXPR_TYPE_INT) {
    val1->type=EXPR_TYPE_DBL;
    val1->val.dblval=(double) val1->val.intval;
  }
  if (val2->type == EXPR_TYPE_INT) {
    val1->type=EXPR_TYPE_DBL;
    val2->val.dblval=(double) val2->val.intval;
  }
  return EXPR_TYPE_DBL;
}

static
EXPR_char 
expr_to_int_or_dbl_logop1 (struct expr_parser* exprobj, struct exprval* val1) {
  EXPR_CHECK_LOGICAL(exprobj, val1);
  return val1->type;
}

static
EXPR_char 
expr_to_int_or_dbl1 (struct expr_parser* exprobj, struct exprval* val1) {
  EXPR_CHECK_NUMBER(exprobj, val1);
  return val1->type;
}

static
void 
expr_to_dbl1 (struct expr_parser* exprobj, struct exprval* val1) {
  EXPR_CHECK_NUMBER(exprobj, val1);
  if (val1->type == EXPR_TYPE_INT) {
    val1->type=EXPR_TYPE_DBL;
    val1->val.dblval=(double) val1->val.intval;
  }
}

static
void 
expr_to_int1 (struct expr_parser* exprobj, struct exprval* val1) {
  EXPR_CHECK_NUMBER(exprobj, val1);
  if (val1->type == EXPR_TYPE_DBL) {
    val1->type=EXPR_TYPE_INT;
    val1->val.intval=(EXPR_int64) val1->val.dblval;
    /* _tmplpro_expnum_debug(*val1, "WARN:converting to `int' from `double'"); */
  }
}

static
void 
expr_to_dbl (struct expr_parser* exprobj, struct exprval* val1, struct exprval* val2) {
  expr_to_dbl1(exprobj, val1);
  expr_to_dbl1(exprobj, val2);
}

static
void 
expr_to_int (struct expr_parser* exprobj, struct exprval* val1, struct exprval* val2) {
  expr_to_int1(exprobj, val1);
  expr_to_int1(exprobj, val2);
}

#define EXPR_CHECK_STRING(pbuff, ptr)   switch (ptr->type) {	\
  case EXPR_TYPE_PSTR: break; \
  case EXPR_TYPE_UPSTR: ptr->val.strval=expr_unescape_pstring_val(pbuff,ptr->val.strval); break; \
  case EXPR_TYPE_INT: ptr->val.strval=int_to_pstring(ptr->val.intval,pbuffer_string(pbuff),pbuffer_size(pbuff)); break; \
  case EXPR_TYPE_DBL: ptr->val.strval=double_to_pstring(ptr->val.dblval,pbuffer_string(pbuff),pbuffer_size(pbuff)); break; \
  default: _tmplpro_expnum_debug(*ptr, "FATAL:internal expr string error. please report\n"); \
  } \
  ptr->type = EXPR_TYPE_PSTR;

static
void 
expr_to_str (struct tmplpro_state* state, struct exprval* val1, struct exprval* val2) {
  EXPR_CHECK_STRING(&(state->expr_left_pbuffer), val1);
  EXPR_CHECK_STRING(&(state->expr_right_pbuffer), val2);
}

static
void 
expr_to_str1 (struct tmplpro_state* state, struct exprval* val1) {
  EXPR_CHECK_STRING(&(state->expr_left_pbuffer), val1);
}

static
int 
is_float_lex (char c)
{
  return (c == '.' || isdigit (c));
}

static
struct exprval 
exp_read_number (struct expr_parser* exprobj, const char* *curposptr, const char* endchars) {
  char c = **curposptr;
  struct exprval retval;
  EXPR_int64 iretval=0;
  double dretval=0;
  EXPR_int64 offset=0;
  int sign=1;
  retval.type=EXPR_TYPE_INT;
  retval.val.intval=0;
  if ((*curposptr)<endchars && '-' == c) {
    sign=-1;
    c = *(++(*curposptr));
  }
  if (! (c == '.' || isdigit (c))) return retval;
  /* double reader
     yylval.dblval=atof(fill_symbuf(is_float_lex).begin);
     return dblNUM;
  */
  while ((*curposptr)<endchars && is_float_lex(c)) {
    if (c == '.') {
      if (retval.type == EXPR_TYPE_INT) {
	retval.type = EXPR_TYPE_DBL;
	dretval=iretval;
	offset=1;
      } else {
	/* (*curposptr)--; ??? */
	log_expr(exprobj, TMPL_LOG_ERROR, "while reading number: %s\n", "uninspected declimal point");
	retval.val.dblval=dretval*sign;
	retval.type=EXPR_TYPE_DBL;
	return retval;
      }
    } else {
      offset*=10;
      if (retval.type == EXPR_TYPE_INT) {
	iretval=iretval*10+c-'0';
      } else {
	dretval=dretval*10+c-'0';
      }
    }
    c = *(++(*curposptr));
  }
  if (retval.type == EXPR_TYPE_INT) {
    retval.val.intval=iretval*sign;
  } else {
    if (offset) dretval/=offset;
    retval.val.dblval=dretval*sign;
  }
  return retval;
}

static
void 
expr_to_num (struct expr_parser* exprobj, struct exprval* val1)
{
  const char* curpos=val1->val.strval.begin;
  EXPR_char type = val1->type;
  if (type == EXPR_TYPE_PSTR || type == EXPR_TYPE_UPSTR) {
    if (NULL==curpos) {
      val1->type = EXPR_TYPE_INT;
      val1->val.intval = 0;
    } else {
      /* escaped string can't be read properly anyway */
      *val1=exp_read_number (exprobj, &curpos, val1->val.strval.endnext);
    }
  }
}

static
void 
expr_to_bool (struct expr_parser* exprobj, struct exprval* val1)
{
  if (val1->type == EXPR_TYPE_PSTR || val1->type == EXPR_TYPE_UPSTR) {
    const char* begin=val1->val.strval.begin;
    const char* end=val1->val.strval.endnext;
    const char* curpos=begin;
    if (begin==end) {
      val1->type = EXPR_TYPE_INT;
      val1->val.intval = 0;
    } else {
      *val1=exp_read_number (exprobj, &curpos, end);
      if (val1->type == EXPR_TYPE_INT) {
	if (val1->val.intval || (curpos == end)) return;
	else val1->val.intval=1; /* strings are true in perl */
      }
      else
	if (val1->type == EXPR_TYPE_DBL) {
	  if (val1->val.dblval || (curpos == end)) return;
	  else val1->val.dblval=1.0; /* strings are true in perl */
	}
    }
  }
}

static
void 
_tmplpro_expnum_debug (struct exprval val, char* msg) 
{
  tmpl_log(TMPL_LOG_DEBUG,"--> debug %s:type %c ",msg,val.type);
  if (val.type == EXPR_TYPE_INT)
    tmpl_log(TMPL_LOG_DEBUG,"ival=%" EXPR_PRId64 "\n",val.val.intval);
  else if (val.type == EXPR_TYPE_DBL)
    tmpl_log(TMPL_LOG_DEBUG,"dval=%f\n",val.val.dblval);
  else if (val.type == EXPR_TYPE_PSTR) {
    tmpl_log(TMPL_LOG_DEBUG,"pstr(%c):",(int) val.type);
    if (NULL==val.val.strval.begin) tmpl_log(TMPL_LOG_DEBUG,"{begin=NULL}");
    if (NULL==val.val.strval.endnext) tmpl_log(TMPL_LOG_DEBUG,"{endnext=NULL}");
    tmpl_log(TMPL_LOG_DEBUG,"sval=%.*s\n",(int)(val.val.strval.endnext-val.val.strval.begin),val.val.strval.begin);
  } else if (val.type == EXPR_TYPE_NULL) {
    tmpl_log(TMPL_LOG_DEBUG,"NULL\n");
    if (NULL!=val.val.strval.begin) tmpl_log(TMPL_LOG_DEBUG,"{begin!=NULL}");
    if (NULL!=val.val.strval.endnext) tmpl_log(TMPL_LOG_DEBUG,"{endnext!=NULL}");
  } else {
    tmpl_log(TMPL_LOG_DEBUG,"unknown(%c) as ival=%" EXPR_PRId64 "\n",(int) val.type,val.val.intval);
  }
}

/* 
 * checks if it is stringval and unescape it (copies to the buffer).
 * it implies that only one string at a time can use buffer.
 */
static
PSTRING
expr_unescape_pstring_val(pbuffer* pbuff, PSTRING val) {
  PSTRING retval;
    const char* curpos = val.begin;
    const char* endnext= val.endnext;
    char* buf=pbuffer_resize(pbuff, endnext-curpos+1);
    char* bufpos = buf;
    while (curpos < endnext) {
      if (*curpos == '\\') {
	*bufpos=*(++curpos);
      } else {
	*bufpos=*curpos;
      }
      curpos++;
      bufpos++;
    }
    retval.begin = buf;
    retval.endnext = bufpos;
    return retval;
}
